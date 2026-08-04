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

# 1. Resource group — everything below lands here. Defaults to an existing,
# externally managed group, which `terraform destroy` will therefore not delete.
module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  create   = var.create_resource_group
  location = var.location
  tags     = local.tags
}

# 2. Network first, so the cluster has a subnet to join.
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

# 3. Container registry.
module "acr" {
  source = "../../modules/acr"

  # No hyphens allowed in ACR names.
  name                = "acr${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku

  tags = local.tags
}

# 4. Key Vault, holding the Postgres credentials the deploy workflows read back.
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

  # Off by default here: the service principal already holds Key Vault Secrets
  # Officer at subscription scope, which any vault created below inherits.
  create_role_assignment = var.create_key_vault_role_assignment
  admin_object_id        = data.azurerm_client_config.current.object_id

  secrets = {
    "postgres-user"     = var.postgres_user
    "postgres-password" = random_password.postgres.result
  }

  tags = local.tags
}

# 5. AKS, joined to the subnet created above.
#
# The cluster object itself lands in the resource group above, but AKS ALWAYS
# creates a second, Azure-managed group for the node infrastructure — the VMSS,
# node disks, and the load balancer backing the frontend Service. That is a
# platform constraint with no opt-out: those resources cannot be placed in the
# same group as the cluster. Naming it explicitly keeps it recognisable instead
# of the default MC_<rg>_<cluster>_<region>.
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

  tags = local.tags
}

# This is what lets the cluster pull from ACR with no imagePullSecrets anywhere
# in the Helm charts. If it is missing, pods fail with ImagePullBackOff.
#
# Creating it requires Owner or RBAC Administrator on the scope — Contributor is
# not enough. Where that cannot be granted, set create_acr_role_assignment =
# false and instead enable the ACR admin user and have the deploy workflows
# create a docker-registry imagePullSecret in the cluster.
resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.create_acr_role_assignment ? 1 : 0

  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}
