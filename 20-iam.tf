data "azurerm_client_config" "current" {}

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
    azurerm_subnet.jumphost_subnet,
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

# checkov:skip=CKV_TF_1:Module uses semantic version tag (v0.2.1) for stability; commit hash would require frequent updates
module "aro_permissions" {
  source = "git::https://github.com/rh-mobb/terraform-aro-permissions.git?ref=v0.2.1"

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
  subnets      = [azurerm_subnet.control_plane_subnet.name, azurerm_subnet.machine_subnet.name]
  route_tables = var.restrict_egress_traffic ? [azurerm_route_table.firewall_rt[0].name] : []

  # further restrict via policy
  managed_resource_group   = "${azurerm_resource_group.main.name}-managed"
  apply_vnet_policy        = var.apply_restricted_policies
  apply_subnet_policy      = var.apply_restricted_policies
  apply_route_table_policy = var.apply_restricted_policies
  apply_nat_gateway_policy = var.apply_restricted_policies
  apply_nsg_policy         = var.apply_restricted_policies
  apply_dns_policy         = var.apply_restricted_policies && var.domain != null && var.domain != ""
  apply_private_dns_policy = var.apply_restricted_policies && var.domain != null && var.domain != ""
  apply_public_ip_policy   = var.apply_restricted_policies && var.api_server_profile != "Public" && var.ingress_profile != "Public"

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

  depends_on = [module.aro_permissions]
}

resource "terraform_data" "installer_credentials" {
  input = {
    client_id     = module.aro_permissions.installer_service_principal_client_id
    client_secret = module.aro_permissions.installer_service_principal_client_secret
  }

  depends_on = [time_sleep.wait]
}
