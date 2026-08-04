# The group is either created here or looked up, never both. Pointing at an
# existing group keeps it OUT of Terraform state, so `terraform destroy` removes
# the workload without touching a shared group it did not create.
resource "azurerm_resource_group" "this" {
  count = var.create ? 1 : 0

  name     = var.name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create ? 0 : 1

  name = var.name
}

locals {
  group = var.create ? azurerm_resource_group.this[0] : data.azurerm_resource_group.existing[0]
}
