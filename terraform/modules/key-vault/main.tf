terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  # RBAC rather than the legacy access-policy model: permissions are ordinary
  # Azure role assignments, so the same SP that runs Terraform can be granted access.
  enable_rbac_authorization = true

  # Reachable from GitHub-hosted runners. No private endpoint by design.
  public_network_access_enabled = true

  # purge_protection MUST stay false in a test environment: with it enabled, a
  # `terraform destroy` soft-deletes the vault and reserves the name, and the next
  # `apply` fails because the name is still held.
  purge_protection_enabled   = false
  soft_delete_retention_days = var.soft_delete_retention_days

  tags = var.tags
}

# In RBAC mode, owning the vault is not enough to read or write its secrets —
# a data-plane role is required. Without this, secret creation below returns 403.
resource "azurerm_role_assignment" "secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_object_id
}

# Azure RBAC assignments take a little while to propagate to the data plane.
# depends_on alone gets the ordering right but still loses the race on a cold apply.
resource "time_sleep" "rbac_propagation" {
  depends_on      = [azurerm_role_assignment.secrets_officer]
  create_duration = "30s"
}

resource "azurerm_key_vault_secret" "this" {
  # keys() of a map holding sensitive values is itself marked sensitive, and
  # for_each rejects sensitive arguments. Only the names are unwrapped here —
  # the values stay sensitive.
  for_each = nonsensitive(toset(keys(var.secrets)))

  name         = each.key
  value        = var.secrets[each.key]
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [time_sleep.rbac_propagation]
}
