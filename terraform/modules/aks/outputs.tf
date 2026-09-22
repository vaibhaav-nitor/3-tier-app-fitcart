output "id" {
  description = "Cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "Cluster name, as passed to `az aks get-credentials --name`."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity. Grant this AcrPull so nodes can pull images without imagePullSecrets."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "AKS-managed resource group holding the VMSS, disks and load balancers."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config_raw" {
  description = "Admin kubeconfig. CI uses `az aks get-credentials` instead; this is here for local break-glass access."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL, used to federate a workload's Kubernetes service account with an Azure AD app registration. Empty unless enable_workload_identity is true."
  value       = try(azurerm_kubernetes_cluster.this.oidc_issuer_url, null)
}

output "key_vault_csi_identity_object_id" {
  description = "Object ID of the Key Vault CSI driver's managed identity. Grant this Key Vault Secrets User before any SecretProviderClass can read a secret. Null unless enable_key_vault_csi is true."
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id, null)
}

output "key_vault_csi_identity_client_id" {
  description = "Client ID of the same identity, as referenced by a SecretProviderClass's userAssignedIdentityID parameter."
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id, null)
}
