resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  version                = var.postgres_version
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  storage_mb = var.storage_mb
  sku_name   = var.sku_name

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false

  # No delegated_subnet_id / private_dns_zone_id: this deliberately stays on
  # public access rather than VNet-integrated private access. A private setup
  # needs a delegated subnet plus a private DNS zone, and would touch the
  # existing AKS cluster's networking to reach it — public + a scoped firewall
  # rule keeps this an isolated addition with zero risk to the running cluster.
  public_network_access_enabled = true

  tags = var.tags

  lifecycle {
    # Azure can reassign the zone on maintenance/restart; without this, every
    # plan after that shows a spurious diff trying to move it back.
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# The well-known "allow public access from any Azure service" rule
# (start/end = 0.0.0.0) — not open to the internet at large, but not scoped to
# a specific caller either. Pinning this to AKS's exact outbound IP would need
# an explicit load_balancer_profile added to the AKS module, which risks a
# disruptive change to the already-running cluster's networking. Tightening
# this later is a one-resource change here, with no effect on the cluster.
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
