
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
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  lifecycle {
    # Ensure cluster is replaced before dependent resources during updates
    create_before_destroy = false
  }

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
    client_id     = module.aro_permissions[0].cluster_service_principal_client_id
    client_secret = module.aro_permissions[0].cluster_service_principal_client_secret
  }

  # Note: No explicit depends_on for modules - implicit dependency via service_principal block above
  #       Destroy order is managed via terraform_data.cluster_destroy_guard_sp in 20-iam.tf
  depends_on = [
    azurerm_firewall_network_rule_collection.firewall_network_rules,
  ]
}

# ARO Cluster - Managed Identity deployment (preview feature)
# Uses ARM template because azurerm_redhat_openshift_cluster doesn't yet support managed identities
# NOTE: Destroy order: Cluster must be deleted BEFORE modules (managed identities)
#       Terraform handles this automatically via implicit dependencies, but if destroy fails,
#       manually delete cluster first: terraform destroy -target=azurerm_resource_group_template_deployment.cluster_managed_identity
resource "azurerm_resource_group_template_deployment" "cluster_managed_identity" {
  count = var.enable_managed_identities ? 1 : 0

  name                = "${var.cluster_name}-managed-identity"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/templates/aro-cluster-managed-identity.json")

  parameters_content = jsonencode({
    clusterName = {
      value = var.cluster_name
    }
    location = {
      value = azurerm_resource_group.main.location
    }
    resourceGroupName = {
      value = azurerm_resource_group.main.name
    }
    managedResourceGroupName = {
      value = "${azurerm_resource_group.main.name}-managed"
    }
    domain = {
      value = local.domain
    }
    pullSecret = {
      value = local.pull_secret != null ? local.pull_secret : ""
    }
    version = {
      value = local.aro_version
    }
    podCidr = {
      value = var.aro_pod_cidr_block
    }
    serviceCidr = {
      value = var.aro_service_cidr_block
    }
    masterVmSize = {
      value = var.main_vm_size
    }
    masterSubnetId = {
      value = azurerm_subnet.control_plane_subnet.id
    }
    workerVmSize = {
      value = var.worker_vm_size
    }
    workerDiskSizeGB = {
      value = var.worker_disk_size_gb
    }
    workerNodeCount = {
      value = var.worker_node_count
    }
    workerSubnetId = {
      value = azurerm_subnet.machine_subnet.id
    }
    apiServerVisibility = {
      value = var.api_server_profile
    }
    ingressVisibility = {
      value = var.ingress_profile
    }
    outboundType = {
      value = var.outbound_type
    }
    managedIdentityAroServiceId = {
      value = local.managed_identity_ids["aro-service"]
    }
    managedIdentityCloudControllerManagerId = {
      value = local.managed_identity_ids["cloud-controller-manager"]
    }
    managedIdentityCloudNetworkConfigId = {
      value = local.managed_identity_ids["cloud-network-config"]
    }
    managedIdentityClusterId = {
      value = local.managed_identity_ids["cluster"]
    }
    managedIdentityDiskCsiDriverId = {
      value = local.managed_identity_ids["disk-csi-driver"]
    }
    managedIdentityFileCsiDriverId = {
      value = local.managed_identity_ids["file-csi-driver"]
    }
    managedIdentityImageRegistryId = {
      value = local.managed_identity_ids["image-registry"]
    }
    managedIdentityIngressId = {
      value = local.managed_identity_ids["ingress"]
    }
    managedIdentityMachineApiId = {
      value = local.managed_identity_ids["machine-api"]
    }
    managedIdentityAroServicePrincipalId = {
      value = local.managed_identity_principal_ids["aro-service"]
    }
    managedIdentityCloudControllerManagerPrincipalId = {
      value = local.managed_identity_principal_ids["cloud-controller-manager"]
    }
    managedIdentityCloudNetworkConfigPrincipalId = {
      value = local.managed_identity_principal_ids["cloud-network-config"]
    }
    managedIdentityDiskCsiDriverPrincipalId = {
      value = local.managed_identity_principal_ids["disk-csi-driver"]
    }
    managedIdentityFileCsiDriverPrincipalId = {
      value = local.managed_identity_principal_ids["file-csi-driver"]
    }
    managedIdentityImageRegistryPrincipalId = {
      value = local.managed_identity_principal_ids["image-registry"]
    }
    managedIdentityIngressPrincipalId = {
      value = local.managed_identity_principal_ids["ingress"]
    }
    managedIdentityMachineApiPrincipalId = {
      value = local.managed_identity_principal_ids["machine-api"]
    }
    tags = {
      value = var.tags
    }
  })

  # Note: No explicit depends_on for modules - implicit dependency via managed_identity_ids in parameters
  #       Destroy order is managed via terraform_data.cluster_destroy_guard_mi in 20-iam.tf
  depends_on = [
    azurerm_firewall_network_rule_collection.firewall_network_rules,
  ]

  lifecycle {
    # Ensure cluster is replaced before dependent resources during updates
    create_before_destroy = false
    # Ignore changes to parameters_content to prevent updates that trigger immutable property errors
    # Tags and other properties can be updated directly via Azure CLI if needed
    # This prevents Terraform from trying to update resourceGroupId which is immutable
    ignore_changes = [parameters_content]
  }
}
