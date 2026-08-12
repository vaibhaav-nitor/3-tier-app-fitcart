terraform {
  backend "azurerm" {
    # Same storage account and container as envs/dev — only the key differs.
    # That separate key is the isolation boundary: this state has no knowledge
    # of dev's resources, so nothing here can modify or destroy them.
    resource_group_name  = "AZET-RG-Daas-Platform"
    storage_account_name = "stfitcarttfstate12345678"
    container_name       = "tfstate"
    key                  = "mdbtest.terraform.tfstate"

    # No use_azuread_auth here on purpose. AAD data-plane access to blobs needs
    # Storage Blob Data Contributor, which neither Contributor nor Owner grants.
    # Left at the default, Terraform looks the account key up through ARM using
    # the same ARM_* credentials, which Contributor does cover.
  }
}
