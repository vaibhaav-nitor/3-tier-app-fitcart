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

# ACR and Key Vault names are global DNS names, as are the two Web App names,
# so all four need a uniquifier.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# 1. Resource group — shared with dev and mdbtest, read-only here too. Because
# Terraform only reads it, `terraform destroy` in this environment removes
# only what's provisioned below and leaves the group itself untouched.
module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  create   = var.create_resource_group
  location = var.location
  tags     = local.tags
}

# 2. Container registry — this environment's own, not dev's or mdbtest's. App
# Service pulls its container images from here, so a push to this stack can
# never interact with the AKS deployments already running in parallel.
module "acr" {
  source = "../../modules/acr"

  # No hyphens allowed in ACR names.
  name                = "acr${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku

  admin_enabled = var.use_acr_admin_credentials

  tags = local.tags
}

# 3. Key Vault — this environment's own, with its own generated password.
# Fully self-contained: nothing is shared with dev's or mdbtest's vault, so
# `destroy` here cleans up every credential this environment created.
resource "random_password" "postgres" {
  length  = 24
  special = true

  # Restricted set on purpose. The password travels through Terraform-managed
  # app settings and through shell variables in the CI workflows. These
  # characters are safe in both.
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

# Mirrors dev/mdbtest so the frontend's runtime config behaves identically
# here. Referenced directly by the frontend Web App's HERO_HIGHLIGHT_TEXT app
# setting below via a Key Vault reference — unlike the AKS charts, no CI step
# reads this value out; App Service resolves it itself.
resource "azurerm_key_vault_secret" "frontend_hero_highlight_text" {
  name         = "version-v1"
  value        = "Progress."
  key_vault_id = module.key_vault.id

  lifecycle {
    ignore_changes = [value]
  }
}

# 4. Managed PostgreSQL — this environment's own database. Same module the
# mdbtest environment already validated; a second, fully independent server,
# shared with neither dev's in-cluster Postgres nor mdbtest's.
module "postgresql" {
  source = "../../modules/postgresql"

  name                = "psql-${local.prefix}-${random_string.suffix.result}"
  resource_group_name = module.resource_group.name

  # NOT module.resource_group.location — see the note on this in
  # terraform/modules/postgresql/main.tf and envs/mdbtest/main.tf. Same
  # regional restriction applies here.
  location = var.postgres_location

  administrator_login    = var.postgres_user
  administrator_password = random_password.postgres.result
  database_name          = "backenddb"

  sku_name   = var.postgres_sku_name
  storage_mb = var.postgres_storage_mb

  tags = local.tags
}

# 5. App Service — Linux containers for the frontend and backend, sharing one
# Plan. This is the compute layer this environment exists to add: the same
# application running on App Service, side by side with the AKS deployment,
# not replacing it.
module "app_service" {
  source = "../../modules/app-service"

  plan_name           = "plan-${local.prefix}"
  frontend_app_name   = "${local.prefix}-frontend-${random_string.suffix.result}"
  backend_app_name    = "${local.prefix}-backend-${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku_name            = var.app_service_sku

  acr_login_server          = module.acr.login_server
  use_acr_admin_credentials = var.use_acr_admin_credentials
  acr_admin_username        = module.acr.admin_username
  acr_admin_password        = module.acr.admin_password

  # Bootstrap tags. The CI workflows retag these on every deploy via
  # `az webapp config container set`, the same role :latest plays for the Helm
  # charts before their first CI run.
  frontend_image = "${module.acr.login_server}/fitcart-frontend:latest"
  backend_image  = "${module.acr.login_server}/fitcart-backend:latest"

  # Key Vault references, resolved by each Web App's own managed identity —
  # this is what "Azure Key Vault for the secrets" means on App Service, no CI
  # step or --set flag involved. They only resolve once
  # create_app_service_key_vault_role_assignment (below) is true; until then
  # the app settings show as unresolved in the portal.
  frontend_app_settings = {
    HERO_HIGHLIGHT_TEXT = "@Microsoft.KeyVault(SecretUri=${module.key_vault.uri}secrets/version-v1/)"
  }

  backend_app_settings = {
    DB_HOST         = module.postgresql.fqdn
    DB_PORT         = "5432"
    DB_NAME         = module.postgresql.database_name
    FRONTEND_ORIGIN = "https://${local.prefix}-frontend-${random_string.suffix.result}.azurewebsites.net"
    DB_USER         = "@Microsoft.KeyVault(SecretUri=${module.key_vault.uri}secrets/postgres-user/)"
    DB_PASSWORD     = "@Microsoft.KeyVault(SecretUri=${module.key_vault.uri}secrets/postgres-password/)"
  }

  tags = local.tags
}

# AcrPull for both Web Apps' managed identities. Same Contributor wall as the
# AKS environments — Owner or RBAC Administrator required to create it.
# use_acr_admin_credentials covers image pulls until this is confirmed live.
resource "azurerm_role_assignment" "frontend_acr_pull" {
  count = var.create_acr_role_assignment ? 1 : 0

  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.app_service.frontend_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  count = var.create_acr_role_assignment ? 1 : 0

  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.app_service.backend_principal_id
  skip_service_principal_aad_check = true
}

# Key Vault Secrets User for both Web Apps' managed identities — required for
# the @Microsoft.KeyVault(...) app settings above to resolve. Same wall again.
# Until granted, the affected app settings resolve to nothing and the
# containers start with an empty HERO_HIGHLIGHT_TEXT / DB credentials.
resource "azurerm_role_assignment" "frontend_key_vault_secrets_user" {
  count = var.create_app_service_key_vault_role_assignment ? 1 : 0

  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.app_service.frontend_principal_id
}

resource "azurerm_role_assignment" "backend_key_vault_secrets_user" {
  count = var.create_app_service_key_vault_role_assignment ? 1 : 0

  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.app_service.backend_principal_id
}
