variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "project" {
  description = "Project short name, used in every resource name."
  type        = string
  default     = "fitcart"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase alphanumeric characters (ACR naming rules)."
  }
}

variable "environment" {
  description = "Environment short name, used in every resource name."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.environment))
    error_message = "environment must be 2-6 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group that holds every resource in this configuration."
  type        = string
  default     = "AZET-RG-Daas-Platform"
}

variable "create_resource_group" {
  description = "Create the resource group. False means it already exists and is managed outside this configuration, so destroy leaves it in place."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region. Only used when create_resource_group is true; otherwise resources follow the existing group's region, which for AZET-RG-Daas-Platform is East US."
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "CIDR for the AKS node subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "acr_sku" {
  description = "Container registry SKU."
  type        = string
  default     = "Basic"
}

variable "aks_node_resource_group_name" {
  description = "Name for the second, Azure-managed group AKS creates for node infrastructure. Null accepts Azure's generated MC_<rg>_<cluster>_<region> name, which matches the convention already used by the other clusters in this resource group."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null tracks the region's default."
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS control plane tier."
  type        = string
  default     = "Free"
}

variable "node_vm_size" {
  description = "VM size for AKS nodes. The B-series is blocked by SKU policy in this subscription, and the permitted b*ps_v2 variants are ARM64, which the amd64 images cannot run on."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_count" {
  description = "Number of AKS nodes."
  type        = number
  default     = 2
}

variable "create_key_vault_role_assignment" {
  description = "Grant the Terraform principal Key Vault Secrets Officer on the vault. False when it already holds that role at subscription scope, which is the case for this environment's service principal."
  type        = bool
  default     = false
}

variable "create_acr_role_assignment" {
  description = "Have Terraform grant the AKS kubelet identity AcrPull on the registry. Requires Owner or RBAC Administrator on the scope; Contributor cannot create role assignments, manually or otherwise. Set false when the grant is made out-of-band."
  type        = bool
  default     = true
}

variable "use_image_pull_secret" {
  description = "Enable the ACR admin user so the deploy workflows can create a docker-registry imagePullSecret. Only needed when no AcrPull assignment exists by any route. Independent of create_acr_role_assignment, so AcrPull can be granted manually without enabling a shared credential."
  type        = bool
  default     = false
}

variable "postgres_user" {
  description = "Postgres username stored in Key Vault. The password is generated, not configured."
  type        = string
  default     = "fitcart"
}

variable "tags" {
  description = "Extra tags merged into the standard project/environment/managedBy set."
  type        = map(string)
  default     = {}
}

# ── Cluster hardening / observability ──────────────────────────────────────

variable "network_policy" {
  description = "Network policy engine passed to the aks module. See terraform/modules/aks/variables.tf."
  type        = string
  default     = "azure"
}

variable "enable_workload_identity" {
  description = "Enables OIDC issuer + workload identity on the cluster. Free and additive."
  type        = bool
  default     = true
}

variable "enable_key_vault_csi" {
  description = "Enables the Key Vault CSI driver add-on. Free to enable; create_key_vault_csi_role_assignment below controls whether it can actually read anything."
  type        = bool
  default     = true
}

variable "create_key_vault_csi_role_assignment" {
  description = "Grant the CSI driver's managed identity Key Vault Secrets User on the vault. Same Contributor wall as create_acr_role_assignment: this subscription's service principal cannot create role assignments, so this stays false until that changes or the grant is made out-of-band."
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enables the Azure Policy (Gatekeeper) add-on."
  type        = bool
  default     = true
}

variable "enable_defender_for_containers" {
  description = "Enables the Microsoft Defender for Containers subscription-wide pricing plan (image scanning + runtime threat detection). Off by default: it is a paid plan, and enabling a Defender plan needs Security Admin (or Owner) on the subscription, which this service principal does not hold — same wall as the ACR role assignment below."
  type        = bool
  default     = false
}

variable "automatic_channel_upgrade" {
  description = "Cluster upgrade channel passed to the aks module."
  type        = string
  default     = "patch"
}

variable "additional_node_pools" {
  description = "Extra user node pools. Empty by default — see the note on this in terraform/modules/aks/variables.tf about current vCPU quota."
  type = map(object({
    vm_size    = string
    node_count = number
    mode       = optional(string, "User")
    priority   = optional(string, "Regular")
  }))
  default = {}
}
