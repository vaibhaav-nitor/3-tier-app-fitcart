project     = "fitcart"
environment = "dev"

# Deploy into this existing, externally managed group. Because Terraform only
# reads it, `terraform destroy` removes the workload and leaves the group itself
# untouched. Resources inherit the group's region, so `location` is unused here.
resource_group_name   = "AZET-RG-Daas-Platform"
create_resource_group = false

# AKS mandates a second group for its node infrastructure (VMSS, node disks,
# load balancer). It cannot share the group above. Left unset so Azure generates
# MC_AZET-RG-Daas-Platform_aks-fitcart-dev_eastus, matching the naming the other
# clusters in this group already use.
# aks_node_resource_group_name = null

vnet_address_space = ["10.0.0.0/16"]
aks_subnet_prefix  = "10.0.1.0/24"

acr_sku = "Basic"

aks_sku_tier = "Free"
node_vm_size = "Standard_B2s"
node_count   = 2

postgres_user = "fitcart"

# The service principal already holds Key Vault Secrets Officer at subscription
# scope, so re-granting it on the vault is redundant — and would fail, since
# Contributor cannot create role assignments.
create_key_vault_role_assignment = false

# AKS needs AcrPull on the registry or every pod lands in ImagePullBackOff.
# Creating that assignment needs Owner or RBAC Administrator — Contributor
# cannot do it from Terraform, the CLI, or the portal. Three workable setups:
#
#   1. Terraform grants it   → create_acr_role_assignment = true,  use_image_pull_secret = false
#   2. Granted out-of-band   → create_acr_role_assignment = false, use_image_pull_secret = false
#   3. No grant possible     → create_acr_role_assignment = false, use_image_pull_secret = true
#
# Setup 2 covers running `az role assignment create` yourself after apply, if
# your own account holds rights the service principal does not.
#
# This environment is on setup 3: both the service principal and the operator
# hold Contributor only, at resource group and subscription scope, so no route
# to a role assignment exists. The ACR admin user is enabled and the deploy
# workflows build a docker-registry secret from it.
#
# Revisit once someone grants RBAC Administrator on the resource group: set
# create_acr_role_assignment = true and use_image_pull_secret = false, re-apply,
# then `kubectl delete secret acr-pull-secret -n fitcart`. The workflows detect
# the change on their own.
create_acr_role_assignment = false
use_image_pull_secret      = true

tags = {
  owner   = "platform"
  purpose = "testing"
}

# subscription_id is deliberately absent — it is supplied per-run via
# TF_VAR_subscription_id (from the AZURE_SUBSCRIPTION_ID secret in CI) so no
# subscription identifier is committed to the repository.
