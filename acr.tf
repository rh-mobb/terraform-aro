# Azure Container Registry (ACR) in Private ARO Clusters
# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-private-link

resource "azurerm_subnet" "private_endpoint_subnet" {
  count                                     = var.acr_private ? 1 : 0
  name                                      = "PrivateEndpoint-subnet"
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.main.name
  address_prefixes                          = [var.aro_private_endpoint_cidr_block]
  private_endpoint_network_policies = "Disabled"
  #private_link_service_network_policies_enabled = false # To verify
}

resource "azurerm_private_dns_zone" "dns" {
  count               = var.acr_private ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  count                 = var.acr_private ? 1 : 0
  name                  = "acr-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.0.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

resource "random_string" "acr" {
  length      = 4
  min_numeric = 4
  keepers = {
    name = "acraro"
  }
}

resource "azurerm_container_registry" "acr" {
  count                         = var.acr_private ? 1 : 0
  name                          = "acraro${random_string.acr.result}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "acr" {
  count               = var.acr_private ? 1 : 0
  name                = "acr-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.0.id

  private_dns_zone_group {
    name = "acr-zonegroup"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns.0.id
    ]
  }

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.acr.0.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}
