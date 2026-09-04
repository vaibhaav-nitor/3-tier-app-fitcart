variable "plan_name" {
  description = "App Service Plan name."
  type        = string
}

variable "frontend_app_name" {
  description = "Frontend Web App name. Globally unique — becomes <name>.azurewebsites.net."
  type        = string
}

variable "backend_app_name" {
  description = "Backend Web App name. Globally unique — becomes <name>.azurewebsites.net."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create these resources in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku_name" {
  description = "App Service Plan SKU. B1 is the cheapest tier that supports always_on and custom containers."
  type        = string
  default     = "B1"
}

variable "always_on" {
  description = "Keep both apps loaded rather than unloading after idle. Requires a Basic tier or higher (not Free/Shared)."
  type        = bool
  default     = true
}

variable "acr_login_server" {
  description = "Registry hostname both apps pull their image from, e.g. acrfitcartapps123456.azurecr.io."
  type        = string
}

variable "frontend_image" {
  description = "Full frontend image reference, e.g. <acr_login_server>/fitcart-frontend:latest."
  type        = string
}

variable "backend_image" {
  description = "Full backend image reference, e.g. <acr_login_server>/fitcart-backend:latest."
  type        = string
}

variable "frontend_port" {
  description = "Port the frontend container listens on. Matches EXPOSE 80 in frontend/Dockerfile."
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port the backend container listens on. Matches EXPOSE 8080 in backend/Dockerfile."
  type        = number
  default     = 8080
}

variable "use_acr_admin_credentials" {
  description = "Pull images using the registry's admin username/password instead of each Web App's managed identity. True is the fallback while no AcrPull role assignment exists (Contributor cannot create one) — same reasoning as the AKS environments' use_image_pull_secret."
  type        = bool
  default     = true
}

variable "acr_admin_username" {
  description = "Registry admin username. Only used when use_acr_admin_credentials is true."
  type        = string
  default     = null
}

variable "acr_admin_password" {
  description = "Registry admin password. Only used when use_acr_admin_credentials is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "frontend_app_settings" {
  description = "App settings (environment variables) for the frontend Web App, merged with WEBSITES_PORT."
  type        = map(string)
  default     = {}
}

variable "backend_app_settings" {
  description = "App settings (environment variables) for the backend Web App, merged with WEBSITES_PORT."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
