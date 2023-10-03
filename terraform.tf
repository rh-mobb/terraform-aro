terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.43"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.75.0"
    }

    azureopenshift = {
      source  = "rh-mobb/azureopenshift"
      version = "0.2.0-pre"
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

provider "azureopenshift" {
  subscription_id = var.subscription_id
}
