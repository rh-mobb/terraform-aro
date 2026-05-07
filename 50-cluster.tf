
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

# ARO Cluster - Managed identity + platform workload identities (AzAPI)
# Vendored pattern: reference/aro-azapi + modules/aro-cluster-azapi (outbound_type parity with SP path)
module "aro_cluster_azapi" {
  count = var.enable_managed_identities ? 1 : 0

  source = "./modules/aro-cluster-azapi"

  cluster_name                = var.cluster_name
  resource_group_name         = module.aro_network.resource_group_name
  managed_resource_group_name = "${module.aro_network.resource_group_name}-managed"
  location                    = module.aro_network.location
  tags                        = local.tags

  domain        = local.domain
  aro_version   = local.aro_version
  pull_secret   = coalesce(local.pull_secret, "")
  outbound_type = var.outbound_type

  api_server_visibility = var.api_server_profile
  ingress_visibility    = var.ingress_profile

  # Must match modules/aro-network: subnet NSG associations are skipped when
  # enable_managed_identities is true. Preconfigured NSG requires NSGs on both
  # master and worker subnets before install (InvalidLinkedVNet otherwise).
  preconfigured_nsg = "Disabled"

  control_plane_subnet_id = module.aro_network.control_plane_subnet_id
  compute_subnet_id       = module.aro_network.machine_subnet_id
  control_plane_vm_size   = var.main_vm_size
  compute_vm_size         = var.worker_vm_size
  compute_vm_disk_size    = var.worker_disk_size_gb
  compute_node_count      = var.worker_node_count

  pod_cidr     = var.aro_pod_cidr_block
  service_cidr = var.aro_service_cidr_block

  cluster_msi_resource_id      = module.aro_mi_identities[0].identity_resource_ids["cluster_msi"]
  platform_workload_identities = local.mi_platform_workload_identities

  timeouts = {
    create = "90m"
    delete = "20m"
  }

  # Entire modules are listed so depends_on stays a static list (see Terraform constraints on depends_on).
  # Only one of the RBAC modules has count = 1 when managed identities are enabled; the other has count = 0.
  depends_on = [
    module.aro_network,
    module.aro_mi_rbac,
    module.aro_mi_rbac_legacy_network,
  ]
}
