
## ARO Cluster

# See docs at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster

locals {
    domain = var.domain != null ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
  length           = 8
  special          = false
  upper            = false
  numeric          = false
}

resource "azurerm_redhat_openshift_cluster" "cluster" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # NOTE: this input is missing to provide parity with the old provider at
  #       https://github.com/rh-mobb/terraform-provider-azureopenshift
  # cluster_resource_group = "${var.cluster_name}-cluster-rg"

  cluster_profile {
    domain      = local.domain
    pull_secret = local.pull_secret
    version     = var.aro_version
  }

  main_profile {
    vm_size   = var.main_vm_size
    subnet_id = azurerm_subnet.control_plane_subnet.id
  }

  worker_profile {
    subnet_id    = azurerm_subnet.machine_subnet.id
    disk_size_gb = var.worker_disk_size_gb
    node_count   = var.worker_node_count
    vm_size      = var.worker_vm_size
  }

  network_profile {
    outbound_type = var.outbound_type
    pod_cidr      = var.aro_pod_cidr_block
    service_cidr  = var.aro_service_cidr_block
  }

  api_server_profile {
    visibility = var.api_server_profile
  }

  ingress_profile {
    visibility = var.ingress_profile
  }

  service_principal {
    client_id     = azuread_application.cluster.client_id
    client_secret = azuread_application_password.cluster.value
  }

  depends_on = [
    azurerm_role_assignment.vnet,
    azurerm_firewall_network_rule_collection.firewall_network_rules
  ]
}

output "console_url" {
  value = azurerm_redhat_openshift_cluster.cluster.console_url
}

output "api_url" {
  value = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].url
}

output "api_server_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].ip_address
}

output "ingress_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.ingress_profile[0].ip_address
}
