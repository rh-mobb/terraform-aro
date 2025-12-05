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
# provider configuration - providers are passed from caller
#
data "azurerm_client_config" "current" {}
