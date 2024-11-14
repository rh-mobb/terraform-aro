data "azurerm_client_config" "current" {}

locals {
  installer_service_principal_name = "${var.cluster_name}-installer"
  cluster_service_principal_name   = "${var.cluster_name}-cluster"
}

module "aro_permissions" {
  source = "git::https://github.com/rh-mobb/terraform-aro-permissions.git?ref=main"

  # NOTE: terraform installation == 'api' installation_type (as opposed to 'cli')
  installation_type = "api"

  # do not output the credentials to a file
  output_as_file = true

  # use custom roles with minimal permissions
  minimal_network_role = "${var.cluster_name}-network"
  minimal_aro_role     = "${var.cluster_name}-aro"

  # cluster parameters
  cluster_name           = var.cluster_name
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
