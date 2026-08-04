project     = "fitcart"
environment = "dev"

# Deploy into this existing, externally managed group. Because Terraform only
# reads it, `terraform destroy` removes the workload and leaves the group itself
# untouched. Resources inherit the group's region, so `location` is unused here.
resource_group_name   = "AZET-RG-Daas-Platform"
create_resource_group = false

# AKS mandates a second group for its node infrastructure (VMSS, node disks,
# load balancer). It cannot share the group above — this only controls its name.
aks_node_resource_group_name = "AZET-RG-Daas-Platform-aks-nodes"

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
# TF_VAR_subscription_id (from the AZURE_SUBSCRIPTION_ID secret in CI) so no
# subscription identifier is committed to the repository.
