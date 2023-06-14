# Restrict Egress Traffic in a Private ARO Cluster
# For enable restrict_egress_traffic define restrict_egress_traffic = "true" in the tfvars / vars

# The Azure FW will be into the ARO subnet following the architecture
# defined in the official docs https://learn.microsoft.com/en-us/azure/openshift/howto-restrict-egress#create-an-azure-firewall

# TODO: Convert from Non Hub-Spoke to Hub-Spoke model (split vNETs)
resource "azurerm_subnet" "firewall_subnet" {
  count                = var.restrict_egress_traffic ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_firewall_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_public_ip" "firewall_ip" {
  count               = var.restrict_egress_traffic ? 1 : 0
  name                = "${local.name_prefix}-fw-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

}

resource "azurerm_firewall" "firewall" {
  count               = var.restrict_egress_traffic ? 1 : 0
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
  count               = var.restrict_egress_traffic ? 1 : 0
  name                = "${local.name_prefix}-fw-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # ARO User Define Routing Route
  route {
    name                   = "${local.name_prefix}-udr"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.0.ip_configuration.0.private_ip_address
  }

  tags = var.tags

}

# TODO: Restrict the FW Network Rules
resource "azurerm_firewall_network_rule_collection" "firewall_network_rules" {
  count               = var.restrict_egress_traffic ? 1 : 0
  name                = "allow-https"
  azure_firewall_name = azurerm_firewall.firewall.0.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-all"
    source_addresses = [
      "*",
    ]
    destination_addresses = [
      "*"
    ]
    protocols = [
      "Any"
    ]
    destination_ports = [
      "1-65535",
    ]
  }
}


resource "azurerm_firewall_application_rule_collection" "firewall_app_rules_aro" {
  count               = var.restrict_egress_traffic ? 1 : 0
  name                = "ARO"
  azure_firewall_name = azurerm_firewall.firewall.0.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 101
  action              = "Allow"

  rule {
    name = "required"
    source_addresses = [
      "*",
    ]
    target_fqdns = [
      "cert-api.access.redhat.com",
      "api.openshift.com",
      "api.access.redhat.com",
      "infogw.api.openshift.com",
      "registry.redhat.io",
      "access.redhat.com",
      "*.quay.io",
      "sso.redhat.com",
      "*.openshiftapps.com",
      "mirror.openshift.com",
      "registry.access.redhat.com",
      "*.redhat.com",
      "*.openshift.com",
      "*.microsoft.com"
    ]
    protocol {
      port = "443"
      type = "Https"
    }
    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name = "azurespecific"
    source_addresses = [
      "*",
    ]
    target_fqdns = [
      "*.azurecr.io",
      "*.azure.com",
      "login.microsoftonline.com",
      "*.windows.net",
      "dc.services.visualstudio.com",
      "*.ods.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.monitoring.azure.com",
      "*.azure.cn"
    ]
    protocol {
      port = "443"
      type = "Https"
    }
    protocol {
      port = "80"
      type = "Http"
    }
  }

}


resource "azurerm_firewall_application_rule_collection" "firewall_app_rules_docker" {
  count               = var.restrict_egress_traffic ? 1 : 0
  name                = "Docker"
  azure_firewall_name = azurerm_firewall.firewall.0.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "docker"
    source_addresses = [
      "*",
    ]
    target_fqdns = [
      "*cloudflare.docker.com",
      "*registry-1.docker.io",
      "apt.dockerproject.org",
      "auth.docker.io"
    ]
    protocol {
      port = "443"
      type = "Https"
    }
    protocol {
      port = "80"
      type = "Http"
    }
  }
}

resource "azurerm_subnet_route_table_association" "firewall_rt_aro_cp_subnet_association" {
  count          = var.restrict_egress_traffic ? 1 : 0
  subnet_id      = azurerm_subnet.control_plane_subnet.id
  route_table_id = azurerm_route_table.firewall_rt.0.id
}

resource "azurerm_subnet_route_table_association" "firewall_rt_aro_machine_subnet_association" {
  count          = var.restrict_egress_traffic ? 1 : 0
  subnet_id      = azurerm_subnet.machine_subnet.id
  route_table_id = azurerm_route_table.firewall_rt.0.id
}
