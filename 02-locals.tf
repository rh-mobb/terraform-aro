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

# Pull secret - read from file if path provided, otherwise null
locals {
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
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
