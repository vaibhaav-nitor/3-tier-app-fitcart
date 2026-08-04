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
