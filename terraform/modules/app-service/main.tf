# One Plan hosting both tiers, mirroring the two-container split already used
# in AKS (helm/frontend, helm/backend) — just on App Service instead of pods.
resource "azurerm_service_plan" "this" {
  name                = var.plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  # Created unconditionally, even while use_acr_admin_credentials is true: the
  # caller wires AcrPull / Key Vault Secrets User role assignments onto
  # frontend_principal_id once ready, with no resource replacement needed to
  # add the identity later.
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = var.always_on

    application_stack {
      docker_image_name        = var.frontend_image
      docker_registry_url      = "https://${var.acr_login_server}"
      docker_registry_username = var.use_acr_admin_credentials ? var.acr_admin_username : null
      docker_registry_password = var.use_acr_admin_credentials ? var.acr_admin_password : null
    }

    # Managed-identity pull needs AcrPull granted on the identity separately —
    # Owner or RBAC Administrator only, same wall documented throughout the
    # AKS environments. Admin credentials are the fallback while that grant is
    # not yet confirmed live.
    container_registry_use_managed_identity = !var.use_acr_admin_credentials
  }

  app_settings = merge(var.frontend_app_settings, {
    WEBSITES_PORT = tostring(var.frontend_port)
  })

  tags = var.tags
}

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = var.always_on

    application_stack {
      docker_image_name        = var.backend_image
      docker_registry_url      = "https://${var.acr_login_server}"
      docker_registry_username = var.use_acr_admin_credentials ? var.acr_admin_username : null
      docker_registry_password = var.use_acr_admin_credentials ? var.acr_admin_password : null
    }

    container_registry_use_managed_identity = !var.use_acr_admin_credentials
  }

  app_settings = merge(var.backend_app_settings, {
    WEBSITES_PORT = tostring(var.backend_port)
  })

  tags = var.tags
}
