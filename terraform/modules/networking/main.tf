resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space

  tags = var.tags
}

# Node pool subnet. Pods do NOT consume addresses here — the cluster uses Azure CNI
# overlay, so pod IPs come from a separate overlay CIDR and this /24 only has to
# hold nodes, internal load balancers, and pod-per-node headroom.
resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]
}
