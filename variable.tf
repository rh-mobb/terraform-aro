variable "cluster_name" {
  type        = string
  default     = "my-aro-cluster"
  description = "ARO cluster name"
}

variable "tags" {
  type        = map(string)
  default     = {
    environment = "development"
    owner = "your@email.address"
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
  default     = "10.0.0.0/22"
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
