variable "name" {
  description = "Resource group name. Created when var.create is true, otherwise looked up and required to exist."
  type        = string
}

variable "create" {
  description = "Create the resource group. Set false to deploy into a group that already exists and is managed elsewhere."
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region. Ignored when var.create is false — the existing group's region is used instead."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the resource group. Ignored when var.create is false."
  type        = map(string)
  default     = {}
}
