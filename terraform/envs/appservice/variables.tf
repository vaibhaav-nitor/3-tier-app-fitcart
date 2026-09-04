variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "project" {
  description = "Project short name, used in every resource name."
  type        = string
  default     = "fitcart"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase alphanumeric characters (ACR naming rules)."
  }
}

variable "environment" {
  description = "Environment short name, used in every resource name. Kept to 4 characters ('apps') because Key Vault names cap at 24 chars: kv-<project>-<environment>-<6-char suffix>."
  type        = string
  default     = "apps"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.environment))
    error_message = "environment must be 2-6 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group that holds every resource in this configuration. The same shared group dev and mdbtest use — read, never managed."
  type        = string
  default     = "AZET-RG-Daas-Platform"
}

variable "create_resource_group" {
  description = "Create the resource group. False means it already exists and is managed outside this configuration, so destroy leaves it in place."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region. Only used when create_resource_group is true; otherwise resources follow the existing group's region."
  type        = string
  default     = "eastus"
}

variable "acr_sku" {
  description = "Container registry SKU."
  type        = string
  default     = "Basic"
}

variable "app_service_sku" {
  description = "App Service Plan SKU. B1 is the cheapest tier supporting always_on and custom containers."
  type        = string
  default     = "B1"
}

variable "create_key_vault_role_assignment" {
  description = "Grant the Terraform principal Key Vault Secrets Officer on the vault. False when it already holds that role at subscription scope, which is the case for this service principal."
  type        = bool
  default     = false
}

variable "create_acr_role_assignment" {
  description = "Have Terraform grant each Web App's managed identity AcrPull on the registry. Requires Owner or RBAC Administrator on the scope; Contributor cannot create role assignments. Set true once that grant is confirmed live on the service principal — see terraform/envs/appservice/appservice.tfvars."
  type        = bool
  default     = false
}

variable "use_acr_admin_credentials" {
  description = "Pull images with the registry's admin username/password instead of AcrPull role assignments. The fallback while create_acr_role_assignment is false. Independent of it, so AcrPull can be granted without also disabling the shared credential in the same apply."
  type        = bool
  default     = true
}

variable "create_app_service_key_vault_role_assignment" {
  description = "Grant each Web App's managed identity Key Vault Secrets User, so its @Microsoft.KeyVault(...) app settings resolve. Requires Owner or RBAC Administrator, same wall as create_acr_role_assignment. While false, those app settings show as unresolved in the portal and the containers start with empty DB credentials."
  type        = bool
  default     = false
}

variable "postgres_user" {
  description = "Postgres username stored in Key Vault, and the managed database's administrator_login."
  type        = string
  default     = "fitcart"
}

variable "postgres_location" {
  description = "Region for the managed database, deliberately separate from the resource group's region. PostgreSQL Flexible Server provisioning is restricted in East US for this subscription, so the database lives in an adjacent region instead."
  type        = string
  default     = "eastus2"
}

variable "postgres_sku_name" {
  description = "Managed PostgreSQL compute tier, in the form <Tier>_<VMSize>."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Managed PostgreSQL storage in MB. 32768 (32Gi) is the Flexible Server minimum."
  type        = number
  default     = 32768
}

variable "tags" {
  description = "Extra tags merged into the standard project/environment/managedBy set."
  type        = map(string)
  default     = {}
}
