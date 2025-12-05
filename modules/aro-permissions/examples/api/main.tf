data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
}

module "example" {
  source = "../../"

  installation_type = "api"

  # cluster parameters
  cluster_name        = "dscott-api"
  vnet                = "dscott-api-aro-vnet-eastus"
  vnet_resource_group = "dscott-api-vnet-rg"
  #network_security_group = "dscott-api-nsg"
  aro_resource_group = {
    name   = "dscott-api-rg"
    create = true
  }


  # service principals
  cluster_service_principal = {
    name   = "dscott-api-custom-cluster"
    create = true
  }

  installer_service_principal = {
    name   = "dscott-api-custom-installer"
    create = true
  }

  # use custom roles with minimal permissions
  minimal_network_role = "dscott-api-network"
  minimal_aro_role     = "dscott-api-aro"

  # explicitly set subscription id and tenant id
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}
