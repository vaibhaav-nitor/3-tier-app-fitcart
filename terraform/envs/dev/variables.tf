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

variable "enable_key_vault_csi" {
  description = "Enable the AKS-managed Secrets Store CSI driver with the Azure Key Vault provider and rotation. Safe on its own — creates the driver and its identity, but nothing consumes it until a SecretProviderClass is added to a chart."
  type        = bool
  default     = false
}

variable "key_vault_csi_rotation_interval" {
  description = "How often the CSI driver polls Key Vault for a changed secret value."
  type        = string
  default     = "2m"
}

variable "create_key_vault_csi_role_assignment" {
  description = "Have Terraform grant the CSI driver's identity Key Vault Secrets User. Requires Owner or RBAC Administrator; Contributor cannot create it. The identity does not exist until enable_key_vault_csi has already been applied once, so this cannot be turned on in the same apply that enables the driver."
  type        = bool
  default     = false
}

variable "postgres_user" {
  description = "Postgres username stored in Key Vault. The password is generated, not configured. Also used as the managed database's administrator_login."
  type        = string
  default     = "fitcart"
}

variable "postgres_sku_name" {
  description = "Managed PostgreSQL compute tier, in the form <Tier>_<VMSize>. Burstable is the cheapest tier and adequate for this workload's actual usage."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Managed PostgreSQL storage in MB. 32768 (32Gi) is the Flexible Server minimum."
  type        = number
  default     = 32768
}

variable "tags" {
  description = "Extra tags merged into the standard project/environment/managedBy set."
  type        = map(string)
  default     = {}
}
