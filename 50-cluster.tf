
## ARO Cluster

# See docs at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster

resource "random_string" "domain" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

# ARO Cluster - Service Principal deployment (when managed identities are disabled)
# NOTE: Destroy order: Cluster must be deleted BEFORE modules (managed identities/service principals)
#       Terraform handles this automatically via implicit dependencies, but if destroy fails,
#       manually delete cluster first: terraform destroy -target=azurerm_redhat_openshift_cluster.cluster
resource "azurerm_redhat_openshift_cluster" "cluster" {
  count = var.enable_managed_identities ? 0 : 1

  # NOTE: use the installer service principal that we created to create our cluster
  provider = azurerm.installer

  name                = var.cluster_name
  location            = module.aro_network.location
  resource_group_name = module.aro_network.resource_group_name
  tags                = local.tags

  lifecycle {
    # Ensure cluster is replaced before dependent resources during updates
    create_before_destroy = false
  }

  cluster_profile {
    domain      = local.domain
    pull_secret = local.pull_secret
    version     = local.aro_version

    managed_resource_group_name = "${module.aro_network.resource_group_name}-managed"
  }

  main_profile {
    vm_size   = var.main_vm_size
    subnet_id = module.aro_network.control_plane_subnet_id
  }

  worker_profile {
    subnet_id    = module.aro_network.machine_subnet_id
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
    client_id     = module.aro_permissions[0].cluster_service_principal_client_id
    client_secret = module.aro_permissions[0].cluster_service_principal_client_secret
  }

  # Implicit dependency on module.aro_permissions via service_principal; destroy removes cluster before IAM cleanup
  depends_on = [
    module.aro_network,
  ]
}

resource "azurerm_redhat_openshift_cluster" "mi_cluster" {
  count = var.enable_managed_identities ? 1 : 0

  # NOTE: use the installer service principal that we created to create our cluster
  provider = azurerm.installer

  name                = var.cluster_name
  location            = module.aro_network.location
  resource_group_name = module.aro_network.resource_group_name
  tags                = local.tags

  lifecycle {
    # Ensure cluster is replaced before dependent resources during updates
    create_before_destroy = false
  }

  cluster_profile {
    domain      = local.domain
    pull_secret = local.pull_secret
    version     = local.aro_version

    managed_resource_group_name = "${module.aro_network.resource_group_name}-managed"
  }

  main_profile {
    vm_size   = var.main_vm_size
    subnet_id = module.aro_network.control_plane_subnet_id
  }

  worker_profile {
    subnet_id    = module.aro_network.machine_subnet_id
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

  identity {
    identity_ids = toset([module.aro_mi_identities[0].identity_resource_ids["cluster_msi"]])
    type         = "UserAssigned"
  }

  platform_workload_identity_profile {
    platform_workload_identity {
      name        = "cloud-controller-manager"
      identity_id = local.mi_platform_workload_identities["cloud-controller-manager"]
    }
    platform_workload_identity {
      name        = "ingress"
      identity_id = local.mi_platform_workload_identities["ingress"]
    }
    platform_workload_identity {
      name        = "machine-api"
      identity_id = local.mi_platform_workload_identities["machine-api"]
    }
    platform_workload_identity {
      name        = "disk-csi-driver"
      identity_id = local.mi_platform_workload_identities["disk-csi-driver"]
    }
    platform_workload_identity {
      name        = "cloud-network-config"
      identity_id = local.mi_platform_workload_identities["cloud-network-config"]
    }
    platform_workload_identity {
      name        = "image-registry"
      identity_id = local.mi_platform_workload_identities["image-registry"]
    }
    platform_workload_identity {
      name        = "file-csi-driver"
      identity_id = local.mi_platform_workload_identities["file-csi-driver"]
    }
    platform_workload_identity {
      name        = "aro-operator"
      identity_id = local.mi_platform_workload_identities["aro-operator"]
    }
  }

  # Implicit dependency on module.aro_permissions via service_principal; destroy removes cluster before IAM cleanup
  depends_on = [
    module.aro_network,
  ]
}