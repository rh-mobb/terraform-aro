
## ARO Cluster

# See docs at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster

resource "random_string" "domain" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

resource "azurerm_redhat_openshift_cluster" "cluster" {
  # NOTE: use the installer service principal that we created to create our cluster
  provider = azurerm.installer

  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  cluster_profile {
    domain      = local.domain
    pull_secret = local.pull_secret
    version     = local.aro_version

    managed_resource_group_name = "${azurerm_resource_group.main.name}-managed"
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

    preconfigured_network_security_group_enabled = true
  }

  api_server_profile {
    visibility = var.api_server_profile
  }

  ingress_profile {
    visibility = var.ingress_profile
  }

  service_principal {
    client_id     = module.aro_permissions.cluster_service_principal_client_id
    client_secret = module.aro_permissions.cluster_service_principal_client_secret
  }

  depends_on = [
    module.aro_permissions,
    azurerm_firewall_network_rule_collection.firewall_network_rules,
  ]
}
