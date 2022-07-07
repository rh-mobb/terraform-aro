terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.24"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.0"
    }

    azureopenshift = {
      source    = "rh-mobb/azureopenshift"
      version   = "~>0.0.3"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

}


provider azureopenshift {}
