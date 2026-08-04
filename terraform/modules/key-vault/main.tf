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

# In RBAC mode, owning the vault does not grant access to the secrets inside it —
# that needs a data-plane role. Skip this when the principal already holds
# "Key Vault Secrets Officer" at a higher scope (subscription or management
# group), which is common with centrally provisioned service principals. Creating
# a role assignment also requires Owner or RBAC Administrator, so a Contributor-
# only principal must set create_role_assignment = false.
resource "azurerm_role_assignment" "secrets_officer" {
  count = var.create_role_assignment ? 1 : 0

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_object_id
}

# A freshly created assignment takes a moment to reach the data plane; depends_on
# fixes ordering but not propagation. Not needed when the role was granted earlier
# at a higher scope, so this waits only when we created the assignment ourselves.
resource "time_sleep" "rbac_propagation" {
  count = var.create_role_assignment ? 1 : 0

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
