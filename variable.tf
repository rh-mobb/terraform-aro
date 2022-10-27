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

variable "aro_virtual_network_firewall_cidr_block" {
  type        = string
  default     = "10.10.0.0/20"
  description = "cidr range for Azure Firewall virtual network"
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

variable "egress_lockdown" {
  type        = bool
  default     = false
  description = "Enable the Egress Lockdown for Private ARO clusters"
}

variable "aro_private" {
  type        = bool
  default     = false
  description = <<EOF
  Deploy an ARO cluster in a private mode. 
  Default "false"
  EOF

}
