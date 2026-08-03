variable "name" {
  description = "Registry name. Globally unique, lowercase alphanumeric only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "ACR names must be 5-50 lowercase alphanumeric characters (no hyphens)."
  }
}

variable "resource_group_name" {
  description = "Resource group to create the registry in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Registry SKU. Basic is sufficient here; Premium is only needed for private endpoints or geo-replication."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of Basic, Standard, Premium."
  }
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}
