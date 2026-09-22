resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # Node resource group holds the VMSS, disks and load balancers AKS creates for us.
  node_resource_group = var.node_resource_group_name

  default_node_pool {
    name = "system"

    vm_size = var.node_vm_size

    # Fixed node_count XOR autoscaler-owned min/max — azurerm rejects setting
    # both. See the comment on var.enable_auto_scaling for why this is off by
    # default and what re-running apply looks like once it is on.
    node_count            = var.enable_auto_scaling ? null : var.node_count
    auto_scaling_enabled  = var.enable_auto_scaling
    min_count             = var.enable_auto_scaling ? var.min_count : null
    max_count             = var.enable_auto_scaling ? var.max_count : null

    zones = length(var.zones) > 0 ? var.zones : null

    # Nodes live in our own VNet subnet rather than an AKS-managed network.
    vnet_subnet_id = var.subnet_id

    os_disk_size_gb = var.os_disk_size_gb
    type            = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"

    # Overlay keeps pod IPs on a separate CIDR, so the node subnet does not have
    # to be sized for every pod. Without it a /24 exhausts quickly.
    network_plugin_mode = "overlay"
    network_policy      = var.network_policy
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  # Empty by default: a fully public API server. Fine for a test cluster reached
  # from GitHub-hosted runners, which have no stable IP to allow-list. Set
  # var.authorized_ip_ranges to narrow it once callers have a stable range.
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  private_cluster_enabled = var.private_cluster_enabled

  # Off by default — see the comment on var.local_account_disabled. The AAD
  # block below only has an effect once this is true.
  local_account_disabled = var.local_account_disabled

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.local_account_disabled ? [1] : []
    content {
      azure_rbac_enabled    = true
      admin_group_object_ids = var.aad_admin_group_object_ids
    }
  }

  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  # AKS-managed Secrets Store CSI driver + Azure Key Vault provider. Creates its
  # own identity (surfaced via the key_vault_csi_identity_object_id output) —
  # that identity still needs a Key Vault Secrets User role assignment before it
  # can read anything, which is a separate, gated step in envs/dev/main.tf.
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_csi ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = var.key_vault_csi_rotation_interval
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  azure_policy_enabled = var.enable_azure_policy

  automatic_channel_upgrade = var.automatic_channel_upgrade

  dynamic "maintenance_window" {
    for_each = var.automatic_channel_upgrade != null ? [1] : []
    content {
      allowed {
        day   = var.maintenance_window_day
        hours = var.maintenance_window_hours
      }
    }
  }

  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags

  # No ignore_changes on node_count. That guard only earns its keep when the
  # cluster autoscaler owns the count, and while enable_auto_scaling is false
  # (the default) node_count is exactly the value that has to move when vCPU
  # quota changes. See var.enable_auto_scaling for the tradeoff once it's true.
}

# Extra user node pools beyond the default system pool. Empty by default — see
# var.additional_node_pools.
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  mode                  = each.value.mode
  priority              = each.value.priority
  # Spot nodes can be evicted at any time; eviction_policy is required in that case.
  eviction_policy = each.value.priority == "Spot" ? "Delete" : null
  vnet_subnet_id  = var.subnet_id

  tags = var.tags
}
