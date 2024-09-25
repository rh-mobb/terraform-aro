locals {
  name_prefix = var.cluster_name
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location

}

## Network resources
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aro_virtual_network_cidr_block]
  tags                = var.tags

}

resource "azurerm_subnet" "control_plane_subnet" {
  name                                           = "${local.name_prefix}-cp-subnet"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.main.name
  address_prefixes                               = [var.aro_control_subnet_cidr_block]
  service_endpoints                              = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
  # private_link_service_network_policies_enabled = false
  # enforce_private_link_service_network_policies  = true
  # private_endpoint_network_policies_enabled = true
  # private_endpoint_network_policies = "Disabled"
  # enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "machine_subnet" {
  name                 = "${local.name_prefix}-machine-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_machine_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}
