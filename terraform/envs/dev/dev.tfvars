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

# Five VNets already in this resource group sit on 10.0.0.0/16 and one on
# 10.1.0.0/16. Overlapping is legal while nothing is peered — those five overlap
# each other today — but it permanently blocks peering and App Service VNet
# integration. 10.50.0.0/16 stays clear of everything currently in use.
# 10.50.2.0/24 is left free for App Service integration in a later phase.
vnet_address_space = ["10.50.0.0/16"]
aks_subnet_prefix  = "10.50.1.0/24"

acr_sku = "Basic"

aks_sku_tier = "Free"

# This subscription restricts which VM SKUs may be used, and the B-series is not
# permitted in eastus. D2s_v3 (2 vCPU, 8 GB) is on the allow-list and supports
# premium storage, which the managed-csi PVC wants.
#
# Do NOT switch to the allowed standard_b2ps_v2 / standard_b2pls_v2 to save cost:
# the "p" denotes ARM64, and the images are built amd64 on GitHub runners, so
# every pod would fail with "exec format error".
node_vm_size = "Standard_D2s_v3"

# One node, because East US regional vCPU quota has only 2 vCPU free and each
# D2s_v3 consumes 2. Two nodes requested 4 and were rejected with
# ErrCode_InsufficientVCPUQuota.
#
# Adequate for the POC: the three tiers request roughly 350m CPU and 850Mi
# total, against about 1.9 vCPU and 5.5Gi allocatable on a single D2s_v3.
# Raise to 2 once the quota is increased — it gives headroom for surge during
# cluster upgrades, which a single-node pool cannot provide.
node_count = 1

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
# Set to setup 1: "Role Based Access Control Administrator" has been requested
# for the service principal specifically so Terraform can create this
# assignment itself. DO NOT apply this until that grant is confirmed live —
# the azurerm_role_assignment.aks_acr_pull resource will fail with an
# authorization error under the previous Contributor-only SP. Once it lands:
# apply, then `kubectl delete secret acr-pull-secret -n fitcart` (the old
# imagePullSecret is no longer referenced but not auto-removed). The deploy
# workflows detect imagePullSecret being empty on their own — no workflow
# change needed.
create_acr_role_assignment = true
use_image_pull_secret      = false

# Enables the AKS-managed Key Vault CSI driver so secret rotation can reach
# running pods without a redeploy. Safe on its own: this alone changes nothing
# for any workload, since no chart references a SecretProviderClass yet.
#
# create_key_vault_csi_role_assignment stays false on its FIRST apply — the
# driver's identity does not exist until this apply completes, so there is
# nothing yet to grant a role to. Same wall as AcrPull otherwise: Contributor
# cannot create the role assignment once the identity does exist either.
#
# Sequence: (1) apply with enable_key_vault_csi = true, role assignment still
# false — this creates the identity (already done: the driver's identity
# exists on kv-fitcart-dev-1kwf3d). (2) read its object ID from
# `terraform output key_vault_csi_identity_object_id`. (3) have that identity
# granted Key Vault Secrets User. (4) re-apply.
#
# Step (3) is now set to happen via Terraform itself
# (create_key_vault_csi_role_assignment = true below), using the same
# "Role Based Access Control Administrator" grant on the service principal
# requested for AcrPull above. DO NOT apply this until that grant is
# confirmed live — azurerm_role_assignment.aks_key_vault_csi_secrets_user
# will fail with an authorization error under Contributor-only.
#
# helm/backend and helm/database now consume this via their keyVault.enabled
# value — see helm/backend/values.yaml. That path stays off in CI until the
# KEY_VAULT_CSI_ENABLED repo variable is set to "true", which should only
# happen after this apply (the CSI identity's role grant) has completed —
# turning it on earlier leaves the SecretProviderClass unable to read the
# vault, and the deploy fails. Also run the "Reloader — Install" workflow
# once (.github/workflows/reloader-deploy.yml) — it is what turns a rotated
# Key Vault value into an actual pod restart, without it the CSI-synced
# Secret updates but running pods never see the change.
enable_key_vault_csi                 = true
key_vault_csi_rotation_interval      = "2m"
create_key_vault_csi_role_assignment = true

tags = {
  owner   = "platform"
  purpose = "testing"
}

# subscription_id is deliberately absent — it is supplied per-run via
# TF_VAR_subscription_id (from the AZURE_SUBSCRIPTION_ID secret in CI) so no
# subscription identifier is committed to the repository.
