project     = "fitcart"
environment = "dev"
location    = "centralindia"

vnet_address_space = ["10.0.0.0/16"]
aks_subnet_prefix  = "10.0.1.0/24"

acr_sku = "Basic"

aks_sku_tier = "Free"
node_vm_size = "Standard_B2s"
node_count   = 2

postgres_user = "fitcart"

tags = {
  owner   = "platform"
  purpose = "testing"
}

# subscription_id is deliberately absent — it is supplied per-run via
# TF_VAR_subscription_id (from AZURE_CREDENTIALS in CI) so no subscription
# identifier is committed to the repository.
