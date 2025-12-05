#
# Output managed identity resource IDs and principal IDs
#

output "managed_identity_ids" {
  description = "Map of managed identity names to their resource IDs"
  value = var.enabled ? {
    "aro-service"              = azurerm_user_assigned_identity.aro_service[0].id
    "cloud-controller-manager" = azurerm_user_assigned_identity.cloud_controller_manager[0].id
    "cloud-network-config"     = azurerm_user_assigned_identity.cloud_network_config[0].id
    "cluster"                  = azurerm_user_assigned_identity.cluster[0].id
    "disk-csi-driver"          = azurerm_user_assigned_identity.disk_csi_driver[0].id
    "file-csi-driver"          = azurerm_user_assigned_identity.file_csi_driver[0].id
    "image-registry"           = azurerm_user_assigned_identity.image_registry[0].id
    "ingress"                  = azurerm_user_assigned_identity.ingress[0].id
    "machine-api"              = azurerm_user_assigned_identity.machine_api[0].id
  } : {}
}

output "managed_identity_principal_ids" {
  description = "Map of managed identity names to their principal IDs"
  value = var.enabled ? {
    "aro-service"              = azurerm_user_assigned_identity.aro_service[0].principal_id
    "cloud-controller-manager" = azurerm_user_assigned_identity.cloud_controller_manager[0].principal_id
    "cloud-network-config"     = azurerm_user_assigned_identity.cloud_network_config[0].principal_id
    "cluster"                  = azurerm_user_assigned_identity.cluster[0].principal_id
    "disk-csi-driver"          = azurerm_user_assigned_identity.disk_csi_driver[0].principal_id
    "file-csi-driver"          = azurerm_user_assigned_identity.file_csi_driver[0].principal_id
    "image-registry"           = azurerm_user_assigned_identity.image_registry[0].principal_id
    "ingress"                  = azurerm_user_assigned_identity.ingress[0].principal_id
    "machine-api"              = azurerm_user_assigned_identity.machine_api[0].principal_id
  } : {}
}
