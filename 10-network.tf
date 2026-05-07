# Core ARO virtual network, subnets, and NSG (resource group + VNet live in modules/aro-network)

module "aro_network" {
  source = "./modules/aro-network"

  name_prefix                    = local.name_prefix
  location                       = var.location
  tags                           = local.tags
  aro_virtual_network_cidr_block = var.aro_virtual_network_cidr_block
  aro_control_subnet_cidr_block  = var.aro_control_subnet_cidr_block
  aro_machine_subnet_cidr_block  = var.aro_machine_subnet_cidr_block
  enable_managed_identities      = var.enable_managed_identities
  egress_traffic_restricted      = var.restrict_egress_traffic
  firewall_subnet_cidr_block     = var.aro_firewall_subnet_cidr_block
}

# State migration for existing deployments (resources were previously at root)
moved {
  from = azurerm_resource_group.main
  to   = module.aro_network.azurerm_resource_group.main
}

moved {
  from = azurerm_virtual_network.main
  to   = module.aro_network.azurerm_virtual_network.main
}

moved {
  from = azurerm_subnet.control_plane_subnet
  to   = module.aro_network.azurerm_subnet.control_plane_subnet
}

moved {
  from = azurerm_subnet.machine_subnet
  to   = module.aro_network.azurerm_subnet.machine_subnet
}

moved {
  from = azurerm_network_security_group.aro
  to   = module.aro_network.azurerm_network_security_group.aro
}

moved {
  from = azurerm_network_security_rule.aro_inbound_api
  to   = module.aro_network.azurerm_network_security_rule.aro_inbound_api
}

moved {
  from = azurerm_network_security_rule.aro_inbound_http
  to   = module.aro_network.azurerm_network_security_rule.aro_inbound_http
}

moved {
  from = azurerm_network_security_rule.aro_inbound_https
  to   = module.aro_network.azurerm_network_security_rule.aro_inbound_https
}

moved {
  from = azurerm_subnet_network_security_group_association.control_plane[0]
  to   = module.aro_network.azurerm_subnet_network_security_group_association.control_plane[0]
}

moved {
  from = azurerm_subnet_network_security_group_association.machine[0]
  to   = module.aro_network.azurerm_subnet_network_security_group_association.machine[0]
}

# Egress / Azure Firewall (previously root 11-egress.tf)
moved {
  from = azurerm_subnet.firewall_subnet[0]
  to   = module.aro_network.azurerm_subnet.firewall_subnet[0]
}

moved {
  from = azurerm_public_ip.firewall_ip[0]
  to   = module.aro_network.azurerm_public_ip.firewall_ip[0]
}

moved {
  from = azurerm_firewall.firewall[0]
  to   = module.aro_network.azurerm_firewall.firewall[0]
}

moved {
  from = azurerm_route_table.firewall_rt[0]
  to   = module.aro_network.azurerm_route_table.firewall_rt[0]
}

moved {
  from = azurerm_firewall_network_rule_collection.firewall_network_rules[0]
  to   = module.aro_network.azurerm_firewall_network_rule_collection.firewall_network_rules[0]
}

moved {
  from = azurerm_firewall_application_rule_collection.firewall_app_rules_aro[0]
  to   = module.aro_network.azurerm_firewall_application_rule_collection.firewall_app_rules_aro[0]
}

moved {
  from = azurerm_firewall_application_rule_collection.firewall_app_rules_docker[0]
  to   = module.aro_network.azurerm_firewall_application_rule_collection.firewall_app_rules_docker[0]
}

moved {
  from = azurerm_subnet_route_table_association.firewall_rt_aro_cp_subnet_association[0]
  to   = module.aro_network.azurerm_subnet_route_table_association.firewall_rt_aro_cp_subnet_association[0]
}

moved {
  from = azurerm_subnet_route_table_association.firewall_rt_aro_machine_subnet_association[0]
  to   = module.aro_network.azurerm_subnet_route_table_association.firewall_rt_aro_machine_subnet_association[0]
}
