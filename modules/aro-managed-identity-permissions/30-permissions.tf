#
# Network object IDs
#
locals {
  network_api_path_prefix   = "${local.network_resource_group_id}/providers/Microsoft.Network"
  vnet_id                   = "${local.network_api_path_prefix}/virtualNetworks/${var.vnet}"
  subnet_ids                = [for s in var.subnets : "${local.vnet_id}/subnets/${s}"]
  network_security_group_id = var.network_security_group != null && var.network_security_group != "" ? "${local.network_api_path_prefix}/networkSecurityGroups/${var.network_security_group}" : null
  route_table_ids           = length(var.route_tables) > 0 ? [for route_table in var.route_tables : "${local.network_api_path_prefix}/routeTables/${route_table}"] : []
  nat_gateway_ids           = length(var.nat_gateways) > 0 ? [for nat_gateway in var.nat_gateways : "${local.network_api_path_prefix}/natGateways/${nat_gateway}"] : []

  has_custom_network_role    = var.minimal_network_role != null && var.minimal_network_role != ""
  has_network_security_group = var.network_security_group != null && var.network_security_group != ""
}

#
# Custom role definitions (if minimal_network_role is specified)
#
locals {
  vnet_permissions = [
    "Microsoft.Network/virtualNetworks/join/action",
    "Microsoft.Network/virtualNetworks/read"
  ]

  subnet_permissions = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/virtualNetworks/subnets/write"
  ]

  route_table_permissions = [
    "Microsoft.Network/routeTables/join/action",
    "Microsoft.Network/routeTables/read"
  ]

  nat_gateway_permissions = [
    "Microsoft.Network/natGateways/join/action",
    "Microsoft.Network/natGateways/read"
  ]

  network_security_group_permissions = [
    "Microsoft.Network/networkSecurityGroups/join/action"
  ]
}

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

resource "azurerm_role_definition" "network_route_tables" {
  count = local.has_custom_network_role ? length(var.route_tables) : 0

  name              = "${var.minimal_network_role}-route-table-${count.index}"
  description       = "Custom role for ARO route table ${var.route_tables[count.index]} for cluster: ${var.cluster_name}"
  scope             = local.route_table_ids[count.index]
  assignable_scopes = [local.route_table_ids[count.index]]

  permissions {
    actions = local.route_table_permissions
  }
}

resource "azurerm_role_definition" "network_nat_gateways" {
  count = local.has_custom_network_role ? length(var.nat_gateways) : 0

  name              = "${var.minimal_network_role}-nat-gateway-${count.index}"
  description       = "Custom role for ARO NAT gateway ${var.nat_gateways[count.index]} for cluster: ${var.cluster_name}"
  scope             = local.nat_gateway_ids[count.index]
  assignable_scopes = [local.nat_gateway_ids[count.index]]

  permissions {
    actions = local.nat_gateway_permissions
  }
}

resource "azurerm_role_definition" "network_network_security_group" {
  count = local.has_custom_network_role && local.has_network_security_group ? 1 : 0

  name              = "${var.minimal_network_role}-nsg"
  description       = "Custom role for ARO network security group for cluster: ${var.cluster_name}"
  scope             = local.network_security_group_id
  assignable_scopes = [local.network_security_group_id]

  permissions {
    actions = local.network_security_group_permissions
  }
}

#
# Resource Provider Service Principal
#
data "azuread_service_principal" "aro_resource_provider" {
  display_name = "Azure Red Hat OpenShift RP"
}

#
# Managed Identity Permissions - VNET
# cloud-network-config, file-csi-driver, and image-registry need VNET permissions
# Note: machine-api does NOT need VNet permissions per Microsoft ARM template - only subnet permissions
#
resource "azurerm_role_assignment" "vnet_cloud_network_config" {
  count = var.enabled ? 1 : 0

  scope                            = local.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cloud_network_config[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vnet_file_csi_driver" {
  count = var.enabled ? 1 : 0

  scope                            = local.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vnet_image_registry" {
  count = var.enabled ? 1 : 0

  scope                            = local.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.image_registry[0].principal_id
  skip_service_principal_aad_check = true
}

#
# Managed Identity Permissions - Subnets
# aro-service, cloud-controller-manager, cloud-network-config, file-csi-driver, image-registry, ingress, machine-api need subnet permissions
# Note: cloud-network-config, file-csi-driver, and image-registry need BOTH VNet and subnet permissions (required by ARO API, even though script.sh only shows VNet)
#
resource "azurerm_role_assignment" "subnet_aro_service" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aro_service[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_cloud_controller_manager" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cloud_controller_manager[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_cloud_network_config" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cloud_network_config[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_file_csi_driver" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_ingress" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.ingress[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_machine_api" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.machine_api[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_image_registry" {
  for_each = var.enabled ? toset(local.subnet_ids) : toset([])

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.image_registry[0].principal_id
  skip_service_principal_aad_check = true
}

#
# Managed Identity Permissions - Route Tables (if route tables exist)
# aro-service, file-csi-driver, machine-api need route table permissions
#
# Route table role assignments - create a map for easier lookup
locals {
  route_table_map = { for idx, rt_id in local.route_table_ids : var.route_tables[idx] => rt_id }
}

resource "azurerm_role_assignment" "route_table_aro_service" {
  for_each = var.enabled ? local.route_table_map : {}

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[index(var.route_tables, each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aro_service[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "route_table_file_csi_driver" {
  for_each = var.enabled ? local.route_table_map : {}

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[index(var.route_tables, each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "route_table_machine_api" {
  for_each = var.enabled ? local.route_table_map : {}

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[index(var.route_tables, each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.machine_api[0].principal_id
  skip_service_principal_aad_check = true
}

#
# Managed Identity Permissions - NAT Gateways (if NAT gateways exist)
# aro-service and file-csi-driver need NAT gateway permissions
#
# NAT gateway role assignments - create a map for easier lookup
locals {
  nat_gateway_map = { for idx, ng_id in local.nat_gateway_ids : var.nat_gateways[idx] => ng_id }
}

resource "azurerm_role_assignment" "nat_gateway_aro_service" {
  for_each = var.enabled ? local.nat_gateway_map : {}

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[index(var.nat_gateways, each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aro_service[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nat_gateway_file_csi_driver" {
  for_each = var.enabled ? local.nat_gateway_map : {}

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[index(var.nat_gateways, each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
  skip_service_principal_aad_check = true
}

#
# Managed Identity Permissions - Network Security Group (if NSG exists)
# aro-service, cloud-controller-manager, file-csi-driver, machine-api need NSG permissions
#
resource "azurerm_role_assignment" "nsg_aro_service" {
  count = var.enabled && local.has_network_security_group ? 1 : 0

  scope                            = local.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aro_service[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_cloud_controller_manager" {
  count = var.enabled && local.has_network_security_group ? 1 : 0

  scope                            = local.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cloud_controller_manager[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_file_csi_driver" {
  count = var.enabled && local.has_network_security_group ? 1 : 0

  scope                            = local.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_machine_api" {
  count = var.enabled && local.has_network_security_group ? 1 : 0

  scope                            = local.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.machine_api[0].principal_id
  skip_service_principal_aad_check = true
}

#
# Installer Permissions (for API installation type)
# Installer (current user) needs Contributor on ARO resource group
#
resource "azurerm_role_assignment" "installer_aro_resource_group" {
  count = var.enabled ? 1 : 0

  scope                = local.aro_resource_group_id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

#
# Resource Provider Service Principal Permissions
# Resource Provider needs VNET, NSG, route tables, and NAT gateway permissions
#
resource "azurerm_role_assignment" "resource_provider_vnet" {
  scope                = local.vnet_id
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = data.azuread_service_principal.aro_resource_provider.object_id
}

resource "azurerm_role_assignment" "resource_provider_route_tables" {
  for_each = local.route_table_map

  scope                = each.value
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[index(var.route_tables, each.key)].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = data.azuread_service_principal.aro_resource_provider.object_id
}

resource "azurerm_role_assignment" "resource_provider_nat_gateways" {
  for_each = local.nat_gateway_map

  scope                = each.value
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[index(var.nat_gateways, each.key)].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = data.azuread_service_principal.aro_resource_provider.object_id
}

resource "azurerm_role_assignment" "resource_provider_network_security_group" {
  count = local.has_network_security_group ? 1 : 0

  scope                = local.network_security_group_id
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = data.azuread_service_principal.aro_resource_provider.object_id
}

#
# Role Assignments Between Managed Identities
# Cluster identity needs "Managed Identity Operator" role on other managed identities
# This matches the ARM template role assignments in Microsoft docs
#
locals {
  managed_identity_operator_role_id = "ef318e2a-8334-4a05-9e4a-295a196c6a6e" # Managed Identity Operator
}

resource "azurerm_role_assignment" "cluster_to_cloud_controller_manager" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.cloud_controller_manager[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_ingress" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.ingress[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_machine_api" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.machine_api[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_disk_csi_driver" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.disk_csi_driver[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_cloud_network_config" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.cloud_network_config[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_image_registry" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.image_registry[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_file_csi_driver" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.file_csi_driver[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_aro_service" {
  count = var.enabled ? 1 : 0

  scope              = azurerm_user_assigned_identity.aro_service[0].id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = azurerm_user_assigned_identity.cluster[0].principal_id
  principal_type     = "ServicePrincipal"
}
