locals {
  prefix = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managedBy   = "terraform"
  })
}

# Object ID of whoever is running Terraform (the CI service principal, or you
# locally). Used to grant Key Vault data-plane access.
data "azurerm_client_config" "current" {}

# ACR and Key Vault names are global DNS names, so they need a uniquifier.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# 1. Resource group — read-only, exactly as envs/dev does. create = false means
# Terraform looks it up rather than owning it, so `destroy` here removes only
# this environment's resources and leaves the shared group untouched.
module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  create   = var.create_resource_group
  location = var.location
  tags     = local.tags
}

# 2. Network. A distinct address space from every VNet already in the group —
# dev sits on 10.50.0.0/16 and six others on 10.0.x / 10.1.x.
module "networking" {
  source = "../../modules/networking"

  vnet_name           = "vnet-${local.prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  address_space     = var.vnet_address_space
  aks_subnet_name   = "snet-aks"
  aks_subnet_prefix = var.aks_subnet_prefix

  tags = local.tags
}

# 3. Container registry — this environment's own, not dev's.
module "acr" {
  source = "../../modules/acr"

  # No hyphens allowed in ACR names.
  name                = "acr${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku

  # The admin user backs the imagePullSecret fallback, needed here for the same
  # reason as dev: the service principal is Contributor-only and cannot create
  # the AcrPull role assignment.
  admin_enabled = var.use_image_pull_secret

  tags = local.tags
}

# 4. Key Vault — this environment's own, with its own generated password. Fully
# self-contained: nothing is shared with dev's vault, so `destroy` cleans up
# every credential this environment created.
resource "random_password" "postgres" {
  length  = 24
  special = true

  # Restricted set on purpose. The password travels through `helm --set`, which
  # gives `,` `.` `\` and `=` special meaning, and through shell variables in the
  # workflow. These characters are safe in all of those.
  override_special = "!#%*-_+"
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                = "kv-${local.prefix}-${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Off, same as dev: the service principal already holds Key Vault Secrets
  # Officer at subscription scope, which any vault created below inherits.
  create_role_assignment = var.create_key_vault_role_assignment
  admin_object_id        = data.azurerm_client_config.current.object_id

  secrets = {
    "postgres-user"     = var.postgres_user
    "postgres-password" = random_password.postgres.result
  }

  tags = local.tags
}

# Mirrors dev so the frontend chart's runtime config behaves identically here.
# The deploy workflow falls back to a default when this is absent, so it is not
# strictly required — it exists to keep the two environments comparable.
resource "azurerm_key_vault_secret" "frontend_hero_highlight_text" {
  name         = "version-v1"
  value        = "Progress."
  key_vault_id = module.key_vault.id

  lifecycle {
    ignore_changes = [value]
  }
}

# 5. Managed PostgreSQL — the resource this whole environment exists to test.
module "postgresql" {
  source = "../../modules/postgresql"

  name                = "psql-${local.prefix}-${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  administrator_login    = var.postgres_user
  administrator_password = random_password.postgres.result
  database_name          = "backenddb"

  sku_name   = var.postgres_sku_name
  storage_mb = var.postgres_storage_mb

  tags = local.tags
}

# 6. AKS — a second, independent cluster. Sized at a single Standard_D2s_v3
# because that is exactly the free East US vCPU quota: 4 free against a 10
# limit, with dev's cluster and agentic-requests-cluster holding 2 each.
module "aks" {
  source = "../../modules/aks"

  name                = "aks-${local.prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  dns_prefix          = "aks-${local.prefix}"
  subnet_id           = module.networking.aks_subnet_id

  node_resource_group_name = var.aks_node_resource_group_name
  kubernetes_version       = var.kubernetes_version
  sku_tier                 = var.aks_sku_tier
  node_vm_size             = var.node_vm_size
  node_count               = var.node_count

  # Off here. The CSI driver is not what this environment is testing, and
  # leaving it out keeps provisioning faster and the surface smaller.
  enable_key_vault_csi = var.enable_key_vault_csi

  tags = local.tags
}

# Same Contributor wall as dev: creating a role assignment needs Owner or RBAC
# Administrator. Gated off, with the ACR admin user enabled instead.
resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.create_acr_role_assignment ? 1 : 0

  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}
