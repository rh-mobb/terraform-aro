resource "azurerm_virtual_network" "firewall_vnet" {
  count               = var.egress_lockdown ? 1 : 0
  name                = "${local.name_prefix}-fw-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aro_virtual_network_cidr_block]
  tags                = var.tags
}

resource "azurerm_subnet" "firewall_subnet" {
  count                = var.egress_lockdown ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.0.name
  address_prefixes     = [var.aro_control_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_public_ip" "firewall_ip" {
  count               = var.egress_lockdown ? 1 : 0
  name                = "${local.name_prefix}-fw-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

}

resource "azurerm_firewall" "firewall" {
  count               = var.egress_lockdown ? 1 : 0
  name                = "${local.name_prefix}-firewall"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "${local.name_prefix}-fw-ip-config"
    subnet_id            = azurerm_subnet.firewall_subnet.0.id
    public_ip_address_id = azurerm_public_ip.firewall_ip.0.id
  }

}

resource "azurerm_route_table" "firewall_rt" {
  name                = "${local.name_prefix}-fw-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  route {
    name           = "${local.name_prefix}-udr"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
  }
  tags = var.tags

}
