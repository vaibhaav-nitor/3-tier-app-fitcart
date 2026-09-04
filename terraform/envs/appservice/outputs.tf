output "resource_group_name" {
  description = "Resource group holding the workload — shared with dev/mdbtest, read-only here."
  value       = module.resource_group.name
}

output "acr_name" {
  description = "This environment's registry name."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "This environment's registry hostname. Image prefix for the CI workflows."
  value       = module.acr.login_server
}

output "key_vault_name" {
  description = "This environment's vault name."
  value       = module.key_vault.name
}

output "postgres_fqdn" {
  description = "Managed database hostname for this environment."
  value       = module.postgresql.fqdn
}

output "frontend_app_name" {
  description = "Frontend Web App name, as passed to `az webapp config container set --name`."
  value       = module.app_service.frontend_name
}

output "backend_app_name" {
  description = "Backend Web App name, as passed to `az webapp config container set --name`."
  value       = module.app_service.backend_name
}

output "frontend_url" {
  description = "Public frontend URL."
  value       = "https://${module.app_service.frontend_hostname}"
}

output "backend_url" {
  description = "Public backend URL."
  value       = "https://${module.app_service.backend_hostname}"
}

# Convenience: everything the appservice-*.yml workflows need, keyed by the
# exact repository variable names they read. Deliberately APPSERVICE_-prefixed
# so these never collide with the unprefixed variables the dev workflows use,
# or the MDBTEST_-prefixed ones the mdbtest workflows use.
output "workflow_env" {
  description = "Values to publish as APPSERVICE_* GitHub repository variables."

  value = {
    APPSERVICE_ACR_NAME          = module.acr.name
    APPSERVICE_ACR_LOGIN_SERVER  = module.acr.login_server
    APPSERVICE_RESOURCE_GROUP    = module.resource_group.name
    APPSERVICE_FRONTEND_APP_NAME = module.app_service.frontend_name
    APPSERVICE_BACKEND_APP_NAME  = module.app_service.backend_name
  }
}
