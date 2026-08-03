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

variable "location" {
  description = "Azure region."
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
