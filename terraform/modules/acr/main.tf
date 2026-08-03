resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # CI authenticates as the service principal via `az acr login`, and AKS pulls
  # via its AcrPull role assignment. Nothing needs the shared admin credential.
  admin_enabled = false

  tags = var.tags
}
