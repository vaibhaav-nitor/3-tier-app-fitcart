resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Normally false: CI authenticates as the service principal via `az acr login`
  # and AKS pulls via its AcrPull role assignment, so nothing needs the shared
  # admin credential. Enable it only where the AcrPull grant cannot be created
  # and the cluster has to fall back to an imagePullSecret.
  admin_enabled = var.admin_enabled

  tags = var.tags
}
