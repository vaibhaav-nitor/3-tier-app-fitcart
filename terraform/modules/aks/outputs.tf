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
