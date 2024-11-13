locals {
  name_prefix = var.cluster_name
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aro_virtual_network_cidr_block]
  tags                = var.tags
}

resource "azurerm_subnet" "control_plane_subnet" {
  name                 = "${local.name_prefix}-cp-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_control_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_subnet" "machine_subnet" {
  name                 = "${local.name_prefix}-machine-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_machine_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_network_security_group" "aro" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_api" {
  name                        = "${local.name_prefix}-inbound-api"
  network_security_group_name = azurerm_network_security_group.aro.name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_http" {
  name                        = "${local.name_prefix}-inbound-http"
  network_security_group_name = azurerm_network_security_group.aro.name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 500
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

// TODO: lockdown for private clusters
resource "azurerm_network_security_rule" "aro_inbound_https" {
  name                        = "${local.name_prefix}-inbound-https"
  network_security_group_name = azurerm_network_security_group.aro.name
  resource_group_name         = azurerm_resource_group.main.name
  priority                    = 501
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "control_plane" {
  subnet_id                 = azurerm_subnet.control_plane_subnet.id
  network_security_group_id = azurerm_network_security_group.aro.id
}

resource "azurerm_subnet_network_security_group_association" "machine" {
  subnet_id                 = azurerm_subnet.machine_subnet.id
  network_security_group_id = azurerm_network_security_group.aro.id
}
