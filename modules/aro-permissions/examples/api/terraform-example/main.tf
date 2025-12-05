terraform {
  required_providers {
    azureopenshift = {
      source = "rh-mobb/azureopenshift"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
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
  subscription_id = data.azurerm_client_config.current.subscription_id
}

data "azurerm_client_config" "current" {}

variable "cluster_sp_client_id" {
  type      = string
  sensitive = true
}

variable "cluster_sp_client_secret" {
  type      = string
  sensitive = true
}

resource "azureopenshift_redhatopenshift_cluster" "cluster" {
  name                   = "dscott-api"
  location               = "eastus"
  resource_group_name    = "dscott-api-rg"
  cluster_resource_group = "dscott-api-cluster-rg"

  master_profile {
    subnet_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/dscott-api-vnet-rg/providers/Microsoft.Network/virtualNetworks/dscott-api-aro-vnet-eastus/subnets/dscott-api-aro-control-subnet-eastus"
  }

  worker_profile {
    subnet_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/dscott-api-vnet-rg/providers/Microsoft.Network/virtualNetworks/dscott-api-aro-vnet-eastus/subnets/dscott-api-aro-machine-subnet-eastus"
  }

  service_principal {
    client_id     = var.cluster_sp_client_id
    client_secret = var.cluster_sp_client_secret
  }

  api_server_profile {
    visibility = "Public"
  }

  ingress_profile {
    visibility = "Public"
  }

  cluster_profile {
    pull_secret = file("~/.azure/aro-pull-secret.txt")
    version     = "4.12.25"
  }
}
