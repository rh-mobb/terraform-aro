# Local Values
#
# Local values used throughout the Terraform configuration

# Domain for the ARO cluster - use provided domain or generate random one
locals {
  domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
}

# Name prefix for all resources (uses cluster name)
locals {
  name_prefix = var.cluster_name
}

# Tags applied to taggable Azure resources.
# User-provided tags override defaults, while ManagedBy remains consistent.
locals {
  tags = merge(
    {
      environment = "development"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Pull secret - read from file if path provided, otherwise null
locals {
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(pathexpand(var.pull_secret_path)) : null
}

# Service principal names for IAM module
locals {
  installer_service_principal_name = "${var.cluster_name}-installer"
  cluster_service_principal_name   = "${var.cluster_name}-cluster"
}

# ARO version - use provided version or auto-detect latest
# Only runs external data source if aro_version is not provided
locals {
  aro_version = var.aro_version != null && var.aro_version != "" ? var.aro_version : data.external.aro_latest_version[0].result.version
}

# Azure resource names for reference/managed_identity (prefixed; API keys for platformWorkloadIdentities are mi_operator_api_keys)
locals {
  mi_operator_api_keys = {
    cloud_controller_manager = "cloud-controller-manager"
    ingress                  = "ingress"
    machine_api              = "machine-api"
    disk_csi_driver          = "disk-csi-driver"
    cloud_network_config     = "cloud-network-config"
    image_registry           = "image-registry"
    file_csi_driver          = "file-csi-driver"
    aro_operator             = "aro-operator"
    cluster_msi              = "cluster"
  }
  mi_identity_azure_names = {
    for k, short in local.mi_operator_api_keys : k => "${var.cluster_name}-${short}"
  }
}

locals {
  # Keys must match ARO platformWorkloadIdentities contract (short operator names)
  mi_platform_workload_identities = var.enable_managed_identities ? {
    for k, v in module.aro_mi_identities[0].identity_resource_ids : local.mi_operator_api_keys[k] => v
    if k != "cluster_msi"
  } : {}
}
