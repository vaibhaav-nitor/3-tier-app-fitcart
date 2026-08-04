variable "name" {
  description = "AKS cluster name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the cluster in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster API server."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID hosting the node pool."
  type        = string
}

variable "node_resource_group_name" {
  description = "Name for the AKS-managed infrastructure resource group. Null lets Azure generate one."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null tracks the region's default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Control plane tier. Free has no API-server SLA, which is fine for testing."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of Free, Standard, Premium."
  }
}

variable "node_vm_size" {
  description = "VM size for the node pool. Must be x86_64 unless the images are cross-built, and must be on the subscription's allowed-SKU list if one is enforced."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_count" {
  description = "Number of nodes in the default pool."
  type        = number
  default     = 2
}

variable "os_disk_size_gb" {
  description = "OS disk size per node."
  type        = number
  default     = 32
}

variable "service_cidr" {
  description = "CIDR for Kubernetes Service ClusterIPs. Must not overlap the VNet address space."
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "IP of the cluster DNS service. Must sit inside service_cidr."
  type        = string
  default     = "10.100.0.10"
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}
