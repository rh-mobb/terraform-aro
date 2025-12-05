# Outputs
#
# All outputs for the Terraform ARO cluster deployment
# Supports both service principal and managed identity deployments

output "console_url" {
  description = "The URL of the ARO cluster web console"
  value = var.enable_managed_identities ? try(
    lookup(
      try(jsondecode(azurerm_resource_group_template_deployment.cluster_managed_identity[0].output_content), {}),
      "consoleUrl",
      { value = null }
    ).value,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].console_url, null)
}

output "api_url" {
  description = "The URL of the ARO cluster API server"
  value = var.enable_managed_identities ? try(
    lookup(
      try(jsondecode(azurerm_resource_group_template_deployment.cluster_managed_identity[0].output_content), {}),
      "apiServerUrl",
      { value = null }
    ).value,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].api_server_profile[0].url, null)
}

output "api_server_ip" {
  description = "The IP address of the ARO cluster API server"
  value = var.enable_managed_identities ? try(
    lookup(
      try(jsondecode(azurerm_resource_group_template_deployment.cluster_managed_identity[0].output_content), {}),
      "apiServerIp",
      { value = null }
    ).value,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].api_server_profile[0].ip_address, null)
}

output "ingress_ip" {
  description = "The IP address of the ARO cluster ingress controller"
  value = var.enable_managed_identities ? try(
    lookup(
      try(jsondecode(azurerm_resource_group_template_deployment.cluster_managed_identity[0].output_content), {}),
      "ingressIp",
      { value = null }
    ).value,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].ingress_profile[0].ip_address, null)
}

output "public_ip" {
  description = "The public IP address of the jumphost VM (only available for private clusters)"
  value       = try(azurerm_public_ip.jumphost_pip[0].ip_address, null)
}

output "cluster_name" {
  description = "The name of the ARO cluster"
  value       = var.cluster_name
}

output "resource_group_name" {
  description = "The name of the resource group containing the ARO cluster"
  value       = azurerm_resource_group.main.name
}
