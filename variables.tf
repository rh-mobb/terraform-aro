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

variable "aro_pod_cidr_block" {
  type        = string
  default     = "10.128.0.0/14"
  description = "cidr range for pods within the cluster network"
}

variable "aro_service_cidr_block" {
  type        = string
  default     = "172.30.0.0/16"
  description = "cidr range for services within the cluster network"
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

  validation {
    condition     = contains(["Public", "Private"], var.api_server_profile)
    error_message = "Invalid 'api_server_profile'. Only 'Public' or 'Private' are allowed."
  }
}

variable "ingress_profile" {
  type        = string
  description = <<EOF
  Ingress Controller Profile Visibility - Public or Private
  Default "Public"
  EOF
  default     = "Public"

  validation {
    condition     = contains(["Public", "Private"], var.ingress_profile)
    error_message = "Invalid 'ingress_profile'. Only 'Public' or 'Private' are allowed."
  }
}

variable "pull_secret_path" {
  type        = string
  default     = null
  description = <<EOF
  Pull Secret for the ARO cluster
  Default null
  EOF
}

variable "aro_version" {
  type        = string
  description = <<EOF
  ARO version
  Default "4.13.23"
  EOF
  default     = "4.13.23"
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

  validation {
    condition     = contains(["Loadbalancer", "UserDefinedRouting"], var.outbound_type)
    error_message = "Invalid 'outbound_type'. Only 'Loadbalancer' or 'UserDefinedRouting' are allowed."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID (needed with the new Auth method)"
}

# NOTE: this is a required input as per the new ARO provider
#       https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster
variable "domain" {
  type        = string
  description = "Domain for the cluster."
  default     = null
}

variable "main_vm_size" {
  type        = string
  description = "VM size for the main, control plane VMs."
  default     = "Standard_D8s_v3"

  validation {
    condition     = var.main_vm_size != "" && var.main_vm_size != null
    error_message = "Invalid 'main_vm_size'. Must be not be empty."
  }
}

variable "worker_vm_size" {
  type        = string
  description = "VM size for the worker VMs."
  default     = "Standard_D4s_v3"

  validation {
    condition     = var.worker_vm_size != "" && var.worker_vm_size != null
    error_message = "Invalid 'worker_vm_size'. Must be not be empty."
  }
}

variable "worker_disk_size_gb" {
  type        = number
  default     = 128
  description = "Disk size for the worker nodes."

  validation {
    condition     = var.worker_disk_size_gb >= 128
    error_message = "Invalid 'worker_disk_size_gb'. Minimum of 128GB."
  }
}

variable "worker_node_count" {
  type        = number
  default     = 3
  description = "Number of worker nodes."

  validation {
    condition     = var.worker_node_count >= 3
    error_message = "Invalid 'worker_node_count'. Minimum of 3."
  }
}
