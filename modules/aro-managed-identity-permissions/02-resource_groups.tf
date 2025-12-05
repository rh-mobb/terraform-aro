# NOTE: create the resource group if it is requested.  this assumes vnet is in the same location as this resource group.
resource "azurerm_resource_group" "aro" {
  count = var.aro_resource_group.create ? 1 : 0

  name     = var.aro_resource_group.name
  location = var.location
}

locals {
  aro_resource_group_name     = var.aro_resource_group.create ? azurerm_resource_group.aro[0].name : var.aro_resource_group.name
  aro_resource_group_id       = var.aro_resource_group.create ? azurerm_resource_group.aro[0].id : "/subscriptions/${var.subscription_id}/resourceGroups/${var.aro_resource_group.name}"
  network_resource_group_name = (var.vnet_resource_group == null || var.vnet_resource_group == "") ? var.aro_resource_group.name : var.vnet_resource_group
  network_resource_group_id   = "/subscriptions/${var.subscription_id}/resourceGroups/${local.network_resource_group_name}"
}
