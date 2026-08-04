output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "Subnet ID to pass to the AKS default node pool."
  value       = azurerm_subnet.aks.id
}
