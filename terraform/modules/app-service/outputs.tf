output "plan_id" {
  description = "App Service Plan ID."
  value       = azurerm_service_plan.this.id
}

output "frontend_principal_id" {
  description = "Object ID of the frontend Web App's system-assigned identity. Grant this AcrPull / Key Vault Secrets User."
  value       = azurerm_linux_web_app.frontend.identity[0].principal_id
}

output "backend_principal_id" {
  description = "Object ID of the backend Web App's system-assigned identity. Grant this AcrPull / Key Vault Secrets User."
  value       = azurerm_linux_web_app.backend.identity[0].principal_id
}

output "frontend_hostname" {
  description = "Frontend's default *.azurewebsites.net hostname."
  value       = azurerm_linux_web_app.frontend.default_hostname
}

output "backend_hostname" {
  description = "Backend's default *.azurewebsites.net hostname."
  value       = azurerm_linux_web_app.backend.default_hostname
}

output "frontend_name" {
  description = "Frontend Web App name, as passed to `az webapp config container set --name`."
  value       = azurerm_linux_web_app.frontend.name
}

output "backend_name" {
  description = "Backend Web App name, as passed to `az webapp config container set --name`."
  value       = azurerm_linux_web_app.backend.name
}
