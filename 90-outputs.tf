# Outputs
#
# All outputs for the Terraform ARO cluster deployment
# Supports both service principal and managed identity deployments

output "console_url" {
  description = "The URL of the ARO cluster web console"
  value = var.enable_managed_identities ? try(
    azurerm_redhat_openshift_cluster.mi_cluster[0].console_url,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].console_url, null)
}

output "api_url" {
  description = "The URL of the ARO cluster API server"
  value = var.enable_managed_identities ? try(
    azurerm_redhat_openshift_cluster.mi_cluster[0].api_server_profile[0].url,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].api_server_profile[0].url, null)
}

output "api_server_ip" {
  description = "The IP address of the ARO cluster API server"
  value = var.enable_managed_identities ? try(
    azurerm_redhat_openshift_cluster.mi_cluster[0].api_server_profile[0].ip_address,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].api_server_profile[0].ip_address, null)
}

output "ingress_ip" {
  description = "The IP address of the ARO cluster ingress controller"
  value = var.enable_managed_identities ? try(
    azurerm_redhat_openshift_cluster.mi_cluster[0].ingress_profile[0].ip_address,
    null
  ) : try(azurerm_redhat_openshift_cluster.cluster[0].ingress_profile[0].ip_address, null)
}

output "public_ip" {
  description = "The public IP address of the jumphost VM (only available for private clusters)"
  value       = try(azurerm_public_ip.jumphost_pip[0].ip_address, null)
}

output "jumphost_ssh_private_key_openssh" {
  description = <<-EOT
  OpenSSH-format private key for the jumphost admin user (`aro`), only populated when SSH keys were Terraform-generated (both `jumphost_ssh_*_path` null).
  Save with care: state and this output are sensitive. Null when BYO SSH paths were provided or no jumphost exists.
  EOT
  sensitive   = true
  value       = try(tls_private_key.jumphost_ssh[0].private_key_openssh, null)
}

output "jumphost_ssh_public_key_openssh" {
  description = "OpenSSH-format public line for jumphost `aro`; only set when keys were Terraform-generated (otherwise use your supplied public key file)."
  value       = try(trimspace(tls_private_key.jumphost_ssh[0].public_key_openssh), null)
}

output "cluster_name" {
  description = "The name of the ARO cluster"
  value       = var.cluster_name
}

output "resource_group_name" {
  description = "The name of the resource group containing the ARO cluster"
  value       = module.aro_network.resource_group_name
}
