project = "fitcart"

# Four characters, not "mdbtest". Key Vault names cap at 24 chars and the
# pattern is kv-<project>-<environment>-<6-char suffix>, so "mdbtest" would
# produce a 25-character name and fail validation before any API call.
environment = "mdbt"

# The same shared group dev uses. Read via a data source, never managed here —
# `terraform destroy` in this environment cannot remove it.
resource_group_name   = "AZET-RG-Daas-Platform"
create_resource_group = false

# Clear of every VNet currently in the group: dev holds 10.50.0.0/16, and six
# others sit on 10.0.0.0/16 or 10.1.0.0/16.
vnet_address_space = ["10.60.0.0/16"]
aks_subnet_prefix  = "10.60.1.0/24"

acr_sku = "Basic"

aks_sku_tier = "Free"
node_vm_size = "Standard_D2s_v3"

# One node = 2 vCPU, which is what East US has free. Quota at the time of
# writing: 6 of 10 regional vCPU used (dev's cluster and
# agentic-requests-cluster, 2 each, plus 2 elsewhere), leaving 4.
node_count = 1

postgres_user       = "fitcart"
postgres_sku_name   = "B_Standard_B1ms"
postgres_storage_mb = 32768

# Same Contributor constraints as dev — see envs/dev/dev.tfvars for the full
# explanation of why neither role assignment can be created here.
create_key_vault_role_assignment = false
create_acr_role_assignment       = false
use_image_pull_secret            = true

# Not what this environment is testing; left off to keep provisioning quick.
enable_key_vault_csi = false

# Tags marking every resource as branch-test infrastructure, so it is obvious
# in the portal which resources belong to this throwaway environment.
tags = {
  owner   = "platform"
  purpose = "managed-db-branch-test"
  branch  = "feature/managed-db"
}

# subscription_id is deliberately absent — supplied per-run via
# TF_VAR_subscription_id (from the AZURE_SUBSCRIPTION_ID secret in CI).
