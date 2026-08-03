output "id" {
  description = "Key Vault ID."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key Vault name, as passed to `az keyvault secret show --vault-name`."
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "Key Vault DNS URI."
  value       = azurerm_key_vault.this.vault_uri
}
