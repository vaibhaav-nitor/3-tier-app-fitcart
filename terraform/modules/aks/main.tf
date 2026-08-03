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
    name       = "system"
    vm_size    = var.node_vm_size
    node_count = var.node_count

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
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  # Public API server. Fine for a test cluster reached from GitHub-hosted runners;
  # locking it down means a private cluster or an authorized-IP list.
  local_account_disabled = false

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # The cluster autoscaler or manual scaling changes this outside Terraform.
      default_node_pool[0].node_count,
    ]
  }
}
