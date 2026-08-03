variable "name" {
  description = "Key Vault name. Globally unique, 3-24 chars, alphanumeric and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault names must be 3-24 chars, start with a letter, end alphanumeric, and contain only letters, digits and hyphens."
  }
}

variable "resource_group_name" {
  description = "Resource group to create the vault in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant that owns the vault."
  type        = string
}

variable "admin_object_id" {
  description = "Object ID granted Key Vault Secrets Officer — the principal running Terraform."
  type        = string
}

variable "secrets" {
  description = "Secrets to store, keyed by secret name."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "sku_name" {
  description = "Vault SKU. standard is sufficient; premium only adds HSM-backed keys."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Days a deleted vault is recoverable. Minimum 7."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to the vault."
  type        = map(string)
  default     = {}
}
