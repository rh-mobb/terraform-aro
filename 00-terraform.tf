terraform {
  required_version = ">= 1.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.21.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.9"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Installer provider - only needed for service principal deployments
# For managed identity deployments, ARM template uses current Azure credentials
# NOTE: Providers can't use count, so we always define it but only use it when enable_managed_identities = false
provider "azurerm" {
  alias           = "installer"
  client_id       = try(terraform_data.installer_credentials[0].output["client_id"], "")
  client_secret   = try(terraform_data.installer_credentials[0].output["client_secret"], "")
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
