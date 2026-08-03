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

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "centralindia"
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
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of AKS nodes."
  type        = number
  default     = 2
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
