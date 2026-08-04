variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the network in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_name" {
  description = "Name of the subnet hosting the AKS node pool."
  type        = string
  default     = "snet-aks"
}

variable "aks_subnet_prefix" {
  description = "CIDR for the AKS node subnet. 10.0.2.0/24 is intentionally left free for App Service VNet integration later."
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
