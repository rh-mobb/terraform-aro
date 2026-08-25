terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.2"
    }
  }
}

data "azurerm_client_config" "current" {}
