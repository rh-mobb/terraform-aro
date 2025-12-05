#
# Create 9 managed identities for ARO cluster
# Based on Microsoft documentation: https://learn.microsoft.com/en-us/azure/openshift/howto-create-openshift-cluster?pivots=aro-deploy-az-cli
#

locals {
  managed_identities = [
    "${var.cluster_name}-aro-service",              # 0 - aro-operator
    "${var.cluster_name}-cloud-controller-manager", # 1
    "${var.cluster_name}-cloud-network-config",     # 2
    "${var.cluster_name}-cluster",                  # 3
    "${var.cluster_name}-disk-csi-driver",          # 4
    "${var.cluster_name}-file-csi-driver",          # 5
    "${var.cluster_name}-image-registry",           # 6
    "${var.cluster_name}-ingress",                  # 7
    "${var.cluster_name}-machine-api",              # 8
  ]
}

resource "azurerm_user_assigned_identity" "aro_service" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[0]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "cloud_controller_manager" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[1]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "cloud_network_config" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[2]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "cluster" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[3]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "disk_csi_driver" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[4]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "file_csi_driver" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[5]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "image_registry" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[6]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "ingress" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[7]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "machine_api" {
  count = var.enabled ? 1 : 0

  name                = local.managed_identities[8]
  location            = var.location
  resource_group_name = local.aro_resource_group_name
  tags                = var.tags
}
