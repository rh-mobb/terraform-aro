#
# minimal network role
#
locals {
  has_custom_network_role = (var.minimal_network_role != null && var.minimal_network_role != "")

  # base permissions needed on vnets
  vnet_permissions_base = [
    "Microsoft.Network/virtualNetworks/join/action",
    "Microsoft.Network/virtualNetworks/read"
  ]

  # base permissions needed on subnets
  # NOTE: once write permissions are removed from subnets, we can create this as a base local
  #       like we do with vnet/route tables/nat gateways and apply them to subnets much
  #       like we do on lines 45-47.
  subnet_permissions = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/virtualNetworks/subnets/write"
  ]

  # base permissions needed by vnets with route tables
  route_table_permissions_base = [
    "Microsoft.Network/routeTables/join/action",
    "Microsoft.Network/routeTables/read"
  ]

  # base permissions needed by vnets with nat gateways
  nat_gateway_permissions_base = [
    "Microsoft.Network/natGateways/join/action",
    "Microsoft.Network/natGateways/read"
  ]

  # base permissions needed by vnets which use a custom network security group
  network_security_group_permissions = [
    "Microsoft.Network/networkSecurityGroups/join/action"
  ]

  # Service principals need write permissions for network objects
  vnet_permissions        = concat(local.vnet_permissions_base, ["Microsoft.Network/virtualNetworks/write"])
  route_table_permissions = concat(local.route_table_permissions_base, ["Microsoft.Network/routeTables/write"])
  nat_gateway_permissions = concat(local.nat_gateway_permissions_base, ["Microsoft.Network/natGateways/write"])
}

# vnet
resource "azurerm_role_definition" "network" {
  count = local.has_custom_network_role ? 1 : 0

  name              = var.minimal_network_role
  description       = "Custom role for ARO network for cluster: ${var.cluster_name}"
  scope             = local.vnet_id
  assignable_scopes = [local.vnet_id]

  permissions {
    actions = local.vnet_permissions
  }
}

# subnet
# TODO: this eventually needs to change scopes to subnets
resource "azurerm_role_definition" "subnet" {
  count = local.has_custom_network_role ? 1 : 0

  name              = "${var.minimal_network_role}-subnet"
  description       = "Custom role for ARO network subnets for cluster: ${var.cluster_name}"
  scope             = local.vnet_id
  assignable_scopes = [local.vnet_id]

  permissions {
    actions = local.subnet_permissions
  }
}

# route tables
resource "azurerm_role_definition" "network_route_tables" {
  count = local.has_custom_network_role ? length(local.route_table_ids) : 0

  name              = "${var.minimal_network_role}-rt${count.index}"
  description       = "Custom role for ARO network route tables for cluster: ${var.cluster_name}"
  scope             = local.route_table_ids[count.index]
  assignable_scopes = [local.route_table_ids[count.index]]

  permissions {
    actions = local.route_table_permissions
  }
}

# nat gateways
resource "azurerm_role_definition" "network_nat_gateways" {
  count = local.has_custom_network_role ? length(local.nat_gateway_ids) : 0

  name              = "${var.minimal_network_role}-natgw${count.index}"
  description       = "Custom role for ARO network NAT gateways for cluster: ${var.cluster_name}"
  scope             = local.nat_gateway_ids[count.index]
  assignable_scopes = [local.nat_gateway_ids[count.index]]

  permissions {
    actions = local.nat_gateway_permissions
  }
}

# network security group
resource "azurerm_role_definition" "network_network_security_group" {
  count = local.has_custom_network_role && (var.network_security_group != null && var.network_security_group != "") ? 1 : 0

  name              = "${var.minimal_network_role}-nsg"
  description       = "Custom role for ARO network NSG for cluster: ${var.cluster_name}"
  scope             = local.network_security_group_id
  assignable_scopes = [local.network_security_group_id]

  permissions {
    actions = local.network_security_group_permissions
  }
}

#
# minimal aro role
#
locals {
  has_custom_aro_role = (var.minimal_aro_role != null && var.minimal_aro_role != "")
  has_custom_des_role = (var.disk_encryption_set != null && var.disk_encryption_set != "")

  # base permissions needed by all
  aro_permissions = [
    "Microsoft.RedHatOpenShift/openShiftClusters/read",
    "Microsoft.RedHatOpenShift/openShiftClusters/write",
    "Microsoft.RedHatOpenShift/openShiftClusters/delete",
    "Microsoft.RedHatOpenShift/openShiftClusters/listCredentials/action",
    "Microsoft.RedHatOpenShift/openShiftClusters/listAdminCredentials/action"
  ]

  # permissions needed when disk encryption set is selected
  des_permissions = [
    "Microsoft.Compute/diskEncryptionSets/read"
  ]
}

# aro
resource "azurerm_role_definition" "aro" {
  count = local.has_custom_aro_role ? 1 : 0

  name              = var.minimal_aro_role
  description       = "Custom role for ARO for cluster: ${var.cluster_name}"
  scope             = local.aro_resource_group_id
  assignable_scopes = [local.aro_resource_group_id]

  permissions {
    actions = local.aro_permissions
  }
}

# disk encryption set
resource "azurerm_role_definition" "des" {
  count = local.has_custom_des_role ? 1 : 0

  name              = "${var.cluster_name}-des"
  description       = "Custom role for disk encryption set for cluster: ${var.cluster_name}"
  scope             = local.disk_encryption_set_id
  assignable_scopes = [local.disk_encryption_set_id]

  permissions {
    actions = local.des_permissions
  }
}
