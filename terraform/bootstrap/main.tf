terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # No backend block on purpose: this configuration CREATES the remote backend,
  # so it has to run on local state. It is the only Terraform in this repo that does.
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Storage account names are globally unique, lowercase alphanumeric, max 24 chars.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.project}-tfstate"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                = "st${var.project}tfstate${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # State files must never be publicly readable.
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  blob_properties {
    # Recovery path if a state file is corrupted by a failed apply.
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
