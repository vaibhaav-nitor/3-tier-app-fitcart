variable "name" {
  description = "Server name. Globally unique — it becomes part of the FQDN (<name>.postgres.database.azure.com)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3-63 chars, lowercase letters/digits/hyphens, starting with a letter."
  }
}

variable "resource_group_name" {
  description = "Resource group to create the server in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL major version. Matches the in-cluster image this replaces."
  type        = string
  default     = "14"
}

variable "administrator_login" {
  description = "Admin username. Cannot be azure_superuser, admin, administrator, root, guest, public, or start with pg_."
  type        = string
}

variable "administrator_password" {
  description = "Admin password."
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Application database created on the server."
  type        = string
  default     = "backenddb"
}

variable "storage_mb" {
  description = "Storage size in MB. 32768 (32Gi) is the Flexible Server minimum."
  type        = number
  default     = 32768
}

variable "sku_name" {
  description = "Compute tier, in the form <Tier>_<VMSize>. Burstable is the cheapest tier and adequate for this workload."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "backup_retention_days" {
  description = "Automated backup retention. 7 is the Flexible Server minimum and included at no extra cost."
  type        = number
  default     = 7
}

variable "allow_azure_services" {
  description = "Add the 'allow access from any Azure service' firewall rule. See the note on this in main.tf for why it is not scoped to a specific IP."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the server."
  type        = map(string)
  default     = {}
}
