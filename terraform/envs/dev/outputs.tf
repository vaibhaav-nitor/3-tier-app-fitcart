output "resource_group_name" {
  description = "Resource group holding the workload. Set as AZURE_RESOURCE_GROUP in the deploy workflows."
  value       = module.resource_group.name
}

output "acr_name" {
  description = "Registry name. Set as ACR_NAME in the deploy workflows."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Registry hostname. Image prefix in the Helm values."
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "Cluster name. Set as AKS_CLUSTER_NAME in the deploy workflows."
  value       = module.aks.name
}

output "key_vault_name" {
  description = "Vault name. Set as KEY_VAULT_NAME in the deploy workflows."
  value       = module.key_vault.name
}

output "vnet_name" {
  description = "Virtual network the cluster is joined to."
  value       = module.networking.vnet_name
}

# Convenience: everything the GitHub Actions `env:` blocks need, in one place.
output "workflow_env" {
  description = "Values to copy into the workflow env: blocks."
  value = {
    ACR_NAME             = module.acr.name
    ACR_LOGIN_SERVER     = module.acr.login_server
    AKS_CLUSTER_NAME     = module.aks.name
    AZURE_RESOURCE_GROUP = module.resource_group.name
    KEY_VAULT_NAME       = module.key_vault.name
  }
}
