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

# ── Networking ────────────────────────────────────────────────────────────

variable "network_policy" {
  description = "Network policy engine. \"azure\" (Azure NPM) works with the azure/overlay plugin combination this module already uses; \"cilium\" needs network_data_plane = \"cilium\" too, which this module does not set. Null disables policy enforcement entirely — any NetworkPolicy manifest is then accepted but has no effect."
  type        = string
  default     = "azure"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "network_policy must be null, \"azure\", \"calico\", or \"cilium\"."
  }
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach the API server. Empty leaves it fully public — the current behaviour, and the only option that works with GitHub-hosted runners, which have no stable outbound IP to allow-list. Only meaningful when private_cluster_enabled is false."
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Put the API server only on a private endpoint. Deliberately not used by this module's caller: GitHub-hosted runners reach the cluster over the public internet, and a private cluster would need a self-hosted runner or a VPN/ExpressRoute path to keep CI working."
  type        = bool
  default     = false
}

# ── Identity & access ─────────────────────────────────────────────────────

variable "enable_workload_identity" {
  description = "Enables OIDC issuer + workload identity, so pods can exchange a Kubernetes service account token for an Azure AD token without a CSI driver or long-lived secret. Free, and additive — nothing has to use it. workload_identity_enabled requires oidc_issuer_enabled, so this variable controls both together."
  type        = bool
  default     = true
}

variable "enable_key_vault_csi" {
  description = "Enables the AKS-managed Secrets Store CSI driver + Azure Key Vault provider add-on. The add-on itself is free to enable; reading a real secret through it additionally needs the driver's identity granted Key Vault Secrets User on the vault (see create_key_vault_csi_role_assignment in envs/dev), which this variable does not do on its own."
  type        = bool
  default     = true
}

variable "key_vault_csi_rotation_interval" {
  description = "How often the CSI driver re-reads secrets from Key Vault and refreshes the mounted files. Only used when enable_key_vault_csi is true."
  type        = string
  default     = "2m"
}

variable "local_account_disabled" {
  description = "Disables the cluster's static admin credential, forcing all kubectl access through Azure AD. Off by default: the deploy workflows currently run `az aks get-credentials` and kubectl directly with no `kubelogin` step and no Kubernetes RBAC role assignment for the CI service principal, so flipping this on would lock CI out until both of those are added."
  type        = bool
  default     = false
}

variable "aad_admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin, when local_account_disabled is true. Ignored otherwise."
  type        = list(string)
  default     = []
}

# ── Scaling ────────────────────────────────────────────────────────────────

variable "enable_auto_scaling" {
  description = "Let the cluster autoscaler own the default node pool's size between min_count and max_count, instead of the fixed node_count. Off by default: this pool already runs at the edge of this subscription's regional vCPU quota (see envs/dev/dev.tfvars), so autoscaling has no headroom to use until that quota grows. When true, Azure can change node_count outside of Terraform; re-running apply after a scaling event is harmless (it will reassert the last-applied count, which the autoscaler then adjusts again as needed) but will show as a plan diff."
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum node count when enable_auto_scaling is true."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum node count when enable_auto_scaling is true."
  type        = number
  default     = 3
}

variable "zones" {
  description = "Availability zones for the default node pool. Empty lets Azure place nodes without zone pinning — the only sensible choice while the pool has a single node, since one node can only ever be in one zone anyway."
  type        = list(string)
  default     = []
}

variable "additional_node_pools" {
  description = "Extra user node pools beyond the default system pool, keyed by pool name (max 12 chars). Empty by default — this subscription's regional vCPU quota does not currently have room for another pool alongside the default one (see envs/dev/dev.tfvars); this exists as a ready-to-use hook for once it does, e.g. a spot pool for non-critical workloads."
  type = map(object({
    vm_size    = string
    node_count = number
    mode       = optional(string, "User")
    priority   = optional(string, "Regular") # "Regular" or "Spot"
  }))
  default = {}
}

# ── Observability ────────────────────────────────────────────────────────

variable "log_analytics_workspace_id" {
  description = "Workspace ID for the Container Insights (oms_agent) add-on. Null skips it — no diagnostic data is collected."
  type        = string
  default     = null
}

variable "enable_azure_policy" {
  description = "Enables the Azure Policy add-on (Gatekeeper-based admission control). Free to enable on its own; it does nothing until policies are actually assigned to the cluster's resource group."
  type        = bool
  default     = true
}

# ── Resilience ────────────────────────────────────────────────────────────

variable "automatic_channel_upgrade" {
  description = "Cluster upgrade channel: null, \"patch\", \"stable\", \"rapid\", or \"node-image\". \"patch\" auto-applies Kubernetes patch releases within the current minor version, which is what most clusters want without manual upgrades."
  type        = string
  default     = "patch"
}

variable "maintenance_window_day" {
  description = "Day automatic upgrades are allowed to run. Only used when automatic_channel_upgrade is not null."
  type        = string
  default     = "Sunday"
}

variable "maintenance_window_hours" {
  description = "Hours of the day (0-23, UTC) automatic upgrades are allowed to run. Only used when automatic_channel_upgrade is not null."
  type        = list(number)
  default     = [2, 3, 4]
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID for customer-managed key encryption of node OS/data disks. Null uses Azure's platform-managed keys, which already encrypt every disk by default — this is only an upgrade path, and creating the Disk Encryption Set + Key Vault key is out of scope for this module."
  type        = string
  default     = null
}
