data "azurerm_client_config" "current" {}

locals {
  installer_service_principal_name = "${var.cluster_name}-installer"
  cluster_service_principal_name   = "${var.cluster_name}-cluster"
}

# NOTE: we need to store a single input that we pass into the aro_permissions module because
#       modules cannot use depends_on and we need to ensure all of our objects have been
#       created prior to setting permissions/policies
resource "terraform_data" "aro_permission_wait" {
  input = {
    cluster_name = var.cluster_name
  }

  # ensure that we create all of our objects before attempting to apply policies that restrict
  # their creation
  depends_on = [
    azurerm_subnet.control_plane_subnet,
    azurerm_subnet.firewall_subnet,
    azurerm_subnet.jumphost-subnet,
    azurerm_subnet.machine_subnet,
    azurerm_subnet.private_endpoint_subnet,
    azurerm_route_table.firewall_rt,
    azurerm_subnet_route_table_association.firewall_rt_aro_cp_subnet_association,
    azurerm_subnet_route_table_association.firewall_rt_aro_machine_subnet_association,
    azurerm_network_security_group.aro,
    azurerm_subnet_network_security_group_association.control_plane,
    azurerm_subnet_network_security_group_association.machine
  ]
}

module "aro_permissions" {
  source = "git::https://github.com/rh-mobb/terraform-aro-permissions.git?ref=v0.1.1"

  # NOTE: terraform installation == 'api' installation_type (as opposed to 'cli')
  installation_type = "api"

  # do not output the credentials to a file
  output_as_file = true

  # use custom roles with minimal permissions
  minimal_network_role = "${var.cluster_name}-network"
  minimal_aro_role     = "${var.cluster_name}-aro"

  # cluster parameters
  cluster_name           = terraform_data.aro_permission_wait.output.cluster_name
  vnet                   = azurerm_virtual_network.main.name
  vnet_resource_group    = azurerm_resource_group.main.name
  network_security_group = azurerm_network_security_group.aro.name

  aro_resource_group = {
    name   = azurerm_resource_group.main.name
    create = false
  }

  # service principals
  cluster_service_principal = {
    name   = local.cluster_service_principal_name
    create = true
  }

  installer_service_principal = {
    name   = local.installer_service_principal_name
    create = true
  }

  # set custom permissions
  nat_gateways = []
  route_tables = var.restrict_egress_traffic ? [azurerm_route_table.firewall_rt[0].name] : []

  # further restrict via policy
  # TODO: uncomment this only when PR https://github.com/Azure/ARO-RP/pull/4087 is
  #       merged and released.  Currently, the subnet/write permission is still 
  #       needed as the resource provider does a CreateOrUpdate regardless of
  #       correct subnet configuration, which needs subnet/write.  Once the above
  #       PR is merged and active, we can uncomment the below.
  #
  # TODO: also ensure this gets moved below apply_vnet_policy for consistency in 
  #       ordering of code.
  #
  # apply_subnet_policy     = var.outbound_type == "UserDefinedRouting"
  managed_resource_group   = "${azurerm_resource_group.main.name}-managed"
  apply_vnet_policy        = var.outbound_type == "UserDefinedRouting"
  apply_route_table_policy = var.outbound_type == "UserDefinedRouting"
  apply_nat_gateway_policy = var.outbound_type == "UserDefinedRouting"
  apply_nsg_policy         = true
  apply_dns_policy         = true
  apply_private_dns_policy = true
  apply_public_ip_policy   = var.api_server_profile != "Public" && var.ingress_profile != "Public"

  # explicitly set location, subscription id and tenant id
  location        = var.location
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}

#
# NOTE: for whatever reason, in order for the installer provider to consume the password we create in the aro_permissions
#       module, we must sleep here and let things calm down first and pass it through a 'terraform_data' resource (it 
#       fails the first time if attempting to use directly but succeeds when continuing to apply)
#
resource "time_sleep" "wait" {
  create_duration = "10s"

  depends_on = [
    module.aro_permissions,
  ]
}

resource "terraform_data" "installer_credentials" {
  input = {
    client_id     = module.aro_permissions.installer_service_principal_client_id
    client_secret = module.aro_permissions.installer_service_principal_client_secret
  }

  depends_on = [time_sleep.wait]
}
