output "resource_group_name" {
  description = "Resource group holding the Terraform state storage account."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Copy this into terraform/envs/dev/backend.tf as storage_account_name."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Blob container holding the state files."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Ready-made backend block for terraform/envs/dev/backend.tf."
  value       = <<-EOT

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "dev.terraform.tfstate"
      }
    }
  EOT
}
