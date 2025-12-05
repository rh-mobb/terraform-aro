terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.21.1"
    }
  }
}

#
# provider configuration - providers are inherited from caller (modern approach)
# This allows the module to use count/for_each on module calls
#
data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}
