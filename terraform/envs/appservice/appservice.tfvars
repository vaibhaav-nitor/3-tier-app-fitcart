project = "fitcart"

# Four characters, not "appservice". Key Vault names cap at 24 chars and the
# pattern is kv-<project>-<environment>-<6-char suffix>, so anything longer
# would fail validation before any API call.
environment = "apps"

# The same shared group dev and mdbtest use. Read via a data source, never
# managed here — `terraform destroy` in this environment cannot remove it.
resource_group_name   = "AZET-RG-Daas-Platform"
create_resource_group = false

acr_sku = "Basic"

# Cheapest Linux tier that supports always_on and custom containers. Free/
# Shared tiers don't support either.
app_service_sku = "B1"

postgres_user = "fitcart"

# East US 2, not East US. PostgreSQL Flexible Server provisioning is
# restricted in East US for this subscription — see the note on this in
# terraform/modules/postgresql/main.tf. East US 2 is adjacent, so
# App Service-to-database latency stays low.
postgres_location   = "eastus2"
postgres_sku_name   = "B_Standard_B1ms"
postgres_storage_mb = 32768

# The service principal already holds Key Vault Secrets Officer at
# subscription scope, so re-granting it on this vault is redundant.
create_key_vault_role_assignment = false

# "Role Based Access Control Administrator" has been granted to the service
# principal (see terraform/envs/dev/dev.tfvars for the same note on the AKS
# side) — confirmed live, so both role assignments are on. The two Web Apps
# now pull images via their own managed identity and resolve their
# @Microsoft.KeyVault(...) app settings — no admin credentials or unresolved
# secrets left anywhere in this environment.
create_acr_role_assignment                   = true
use_acr_admin_credentials                    = false
create_app_service_key_vault_role_assignment = true

tags = {
  owner   = "platform"
  purpose = "app-service-parallel-deployment"
  branch  = "feature/app-service-deployment"
}

# subscription_id is deliberately absent — supplied per-run via
# TF_VAR_subscription_id (from the AZURE_SUBSCRIPTION_ID secret in CI).
