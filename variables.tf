variable "cluster_name" {
  type        = string
  default     = "my-aro-cluster"
  description = "ARO cluster name"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "development"
    owner       = "your@email.address"
  }
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "ARO resource group name"
}

variable "aro_virtual_network_cidr_block" {
  type        = string
  default     = "10.0.0.0/20"
  description = "cidr range for aro virtual network"
}

variable "aro_control_subnet_cidr_block" {
  type        = string
  default     = "10.0.0.0/23"
  description = "cidr range for aro control plane subnet"
}

variable "aro_machine_subnet_cidr_block" {
  type        = string
  default     = "10.0.2.0/23"
  description = "cidr range for aro machine subnet"
}

variable "aro_jumphost_subnet_cidr_block" {
  type        = string
  default     = "10.0.4.0/23"
  description = "cidr range for bastion / jumphost"
}

variable "aro_firewall_subnet_cidr_block" {
  type        = string
  default     = "10.0.6.0/23"
  description = "cidr range for Azure Firewall virtual network"
}

variable "aro_private_endpoint_cidr_block" {
  type        = string
  default     = "10.0.8.0/23"
  description = "cidr range for Azure Firewall virtual network"
}

variable "restrict_egress_traffic" {
  type        = bool
  default     = false
  description = <<EOF
  Enable the Restrict Egress Traffic for Private ARO clusters.
  Default "false"
  EOF
}

variable "api_server_profile" {
  type        = string
  description = <<EOF
  Api Server Profile Visibility - Public or Private
  Default "Public"
  EOF
  default     = "Public"
}

variable "ingress_profile" {
  type        = string
  description = <<EOF
  Ingress Controller Profile Visibility - Public or Private
  Default "Public"
  EOF
  default     = "Public"
}

variable "pull_secret_path" {
  type        = string
  default     = false
  description = <<EOF
  Pull Secret for the ARO cluster
  Default "false"
  EOF
}

variable "aro_version" {
  type        = string
  description = <<EOF
  ARO version
  Default "4.12.25"
  EOF
  default     = "4.12.25"
}

variable "acr_private" {
  type        = bool
  default     = false
  description = <<EOF
  Deploy ACR for Private ARO clusters.
  Default "false"
  EOF
}

variable "outbound_type" {
  type        = string
  description = <<EOF
  Outbound Type - Loadbalancer or UserDefinedRouting
  Default "Loadbalancer"
  EOF
  default     = "Loadbalancer"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID (needed with the new Auth method)"
  default     = "Use_Your_Subs_ID"
}
