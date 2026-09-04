output "id" {
  description = "Registry ID. Scope for the AcrPull role assignment."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Registry name, as passed to `az acr login --name`."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry hostname, e.g. acrfitcartdev123.azurecr.io. Prefix for image references."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username. Only set when admin_enabled is true."
  value       = azurerm_container_registry.this.admin_username
}

output "admin_password" {
  description = "Admin password. Only set when admin_enabled is true."
  value       = azurerm_container_registry.this.admin_password
  sensitive   = true
}
