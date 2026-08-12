output "resource_group_name" {
  description = "Resource group holding the workload — shared with dev, read-only here."
  value       = module.resource_group.name
}

output "acr_name" {
  description = "This environment's registry name."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "This environment's registry hostname. Image prefix in the Helm values."
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "This environment's cluster name."
  value       = module.aks.name
}

output "key_vault_name" {
  description = "This environment's vault name."
  value       = module.key_vault.name
}

output "postgres_fqdn" {
  description = "Managed database hostname for this environment."
  value       = module.postgresql.fqdn
}

output "vnet_name" {
  description = "Virtual network the cluster is joined to."
  value       = module.networking.vnet_name
}

# Convenience: everything the *-mdbtest workflows need, keyed by the exact
# repository variable names they read. Deliberately MDBTEST_-prefixed so these
# never collide with the variables the dev workflows use.
output "workflow_env" {
  description = "Values to publish as MDBTEST_* GitHub repository variables."

  value = {
    MDBTEST_ACR_NAME         = module.acr.name
    MDBTEST_ACR_LOGIN_SERVER = module.acr.login_server
    MDBTEST_AKS_CLUSTER_NAME = module.aks.name
    MDBTEST_KEY_VAULT_NAME   = module.key_vault.name
    MDBTEST_POSTGRES_HOST    = module.postgresql.fqdn
  }
}
