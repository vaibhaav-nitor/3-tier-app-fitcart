terraform {
  backend "azurerm" {
    resource_group_name = "AZET-RG-Daas-Platform"

    # Replace with the storage_account_name printed by terraform/bootstrap.
    # It carries a random suffix, so it cannot be known ahead of time.
    storage_account_name = "REPLACE_WITH_BOOTSTRAP_OUTPUT"

    container_name = "tfstate"
    key            = "dev.terraform.tfstate"

    # No use_azuread_auth here on purpose. AAD data-plane access would need the
    # service principal to hold Storage Blob Data Contributor, which subscription
    # Owner does NOT include. Left at the default, Terraform looks the account key
    # up through ARM using the same ARM_* credentials, which Owner does cover.
  }
}
