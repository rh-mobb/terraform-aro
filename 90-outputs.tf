# Outputs
#
# All outputs for the Terraform ARO cluster deployment

output "console_url" {
  description = "The URL of the ARO cluster web console"
  value       = azurerm_redhat_openshift_cluster.cluster.console_url
}

output "api_url" {
  description = "The URL of the ARO cluster API server"
  value       = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].url
}

output "api_server_ip" {
  description = "The IP address of the ARO cluster API server"
  value       = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].ip_address
}

output "ingress_ip" {
  description = "The IP address of the ARO cluster ingress controller"
  value       = azurerm_redhat_openshift_cluster.cluster.ingress_profile[0].ip_address
}

output "public_ip" {
  description = "The public IP address of the jumphost VM (only available for private clusters)"
  value       = try(azurerm_public_ip.jumphost_pip[0].ip_address, null)
}

output "cluster_name" {
  description = "The name of the ARO cluster"
  value       = azurerm_redhat_openshift_cluster.cluster.name
}

output "resource_group_name" {
  description = "The name of the resource group containing the ARO cluster"
  value       = azurerm_resource_group.main.name
}
