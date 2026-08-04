variable "subscription_id" {
  description = "Azure subscription ID to provision the state backend in."
  type        = string
}

variable "project" {
  description = "Project short name. Used in resource names, so keep it lowercase and alphanumeric."
  type        = string
  default     = "fitcart"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase alphanumeric characters (storage account naming rules)."
  }
}

variable "resource_group_name" {
  description = "Resource group to hold the Terraform state storage account."
  type        = string
  default     = "AZET-RG-Daas-Platform"
}

variable "create_resource_group" {
  description = "Create the resource group. False means it already exists and is managed elsewhere."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region. Only used when create_resource_group is true; otherwise the existing group's region is used."
  type        = string
  default     = "centralindia"
}

variable "tags" {
  description = "Tags applied to all bootstrap resources."
  type        = map(string)
  default = {
    project   = "fitcart"
    managedBy = "terraform"
    purpose   = "tfstate"
  }
}
