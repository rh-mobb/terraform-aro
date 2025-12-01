variable "cluster_name" {
  type        = string
  default     = "my-aro-cluster"
  description = "Name of the Azure Red Hat OpenShift (ARO) cluster. This name will be used as a prefix for all created resources."
}

variable "tags" {
  type = map(string)
  default = {
    environment = "development"
    owner       = "your@email.address"
  }
  description = "Map of tags to apply to all Azure resources. Default tags include 'environment' and 'owner'. The 'ManagedBy' tag is automatically added."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region where the ARO cluster and associated resources will be deployed. Example: 'eastus', 'westus2', 'westeurope'"
}

variable "aro_virtual_network_cidr_block" {
  type        = string
  default     = "10.0.0.0/20"
  description = "CIDR block for the ARO virtual network. Must be large enough to accommodate all subnets. Default: 10.0.0.0/20 (4096 addresses)"
}

variable "aro_control_subnet_cidr_block" {
  type        = string
  default     = "10.0.0.0/23"
  description = "CIDR block for the ARO control plane subnet. Must be within the virtual network CIDR. Default: 10.0.0.0/23 (512 addresses)"
}

variable "aro_machine_subnet_cidr_block" {
  type        = string
  default     = "10.0.2.0/23"
  description = "CIDR block for the ARO worker node (machine) subnet. Must be within the virtual network CIDR and not overlap with other subnets. Default: 10.0.2.0/23 (512 addresses)"
}

variable "aro_jumphost_subnet_cidr_block" {
  type        = string
  default     = "10.0.4.0/23"
  description = "CIDR block for the jumphost/bastion subnet. Used for private cluster access. Must be within the virtual network CIDR. Default: 10.0.4.0/23 (512 addresses)"
}

variable "aro_firewall_subnet_cidr_block" {
  type        = string
  default     = "10.0.6.0/23"
  description = "CIDR block for the Azure Firewall subnet. Required when restrict_egress_traffic is enabled. Must be within the virtual network CIDR. Default: 10.0.6.0/23 (512 addresses)"
}

variable "aro_private_endpoint_cidr_block" {
  type        = string
  default     = "10.0.8.0/23"
  description = "CIDR block for the private endpoint subnet. Used for Azure Container Registry private endpoints when acr_private is enabled. Must be within the virtual network CIDR. Default: 10.0.8.0/23 (512 addresses)"
}

variable "aro_pod_cidr_block" {
  type        = string
  default     = "10.128.0.0/14"
  description = "CIDR block for Kubernetes pods within the ARO cluster. Must not overlap with the virtual network CIDR or service CIDR. Default: 10.128.0.0/14"
}

variable "aro_service_cidr_block" {
  type        = string
  default     = "172.30.0.0/16"
  description = "CIDR block for Kubernetes services within the ARO cluster. Must not overlap with the virtual network CIDR or pod CIDR. Default: 172.30.0.0/16"
}

variable "restrict_egress_traffic" {
  type        = bool
  default     = false
  description = <<EOF
  Enable egress traffic restriction via Azure Firewall for private ARO clusters.
  When enabled, creates an Azure Firewall and routes all egress traffic through it.
  Recommended for production deployments. Default: false (permissive for development/example use)
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
  Path to the Red Hat pull secret file for the ARO cluster.
  Required for accessing private container registries. Download from: https://console.redhat.com/openshift/install/pull-secret
  Default: null (no pull secret)
  EOF
  nullable    = true
}

variable "aro_version" {
  type        = string
  description = <<EOF
  Azure Red Hat OpenShift version to deploy.
  If not specified (null), the latest available version for the region will be automatically detected.
  Check available versions with: az aro get-versions -l <location>
  Default: null (auto-detect latest)
  EOF
  default     = null
  nullable    = true
}

variable "acr_private" {
  type        = bool
  default     = false
  description = <<EOF
  Deploy Azure Container Registry (ACR) with private endpoint for private ARO clusters.
  When enabled, creates a Premium ACR with private endpoint connectivity.
  Default: false
  EOF
}

variable "outbound_type" {
  type        = string
  description = <<EOF
  Outbound type for the ARO cluster egress traffic.
  - "Loadbalancer": Uses Azure Load Balancer (default, requires public IP)
  - "UserDefinedRouting": Routes traffic through Azure Firewall (requires restrict_egress_traffic=true)
  Default: "Loadbalancer"
  EOF
  default     = "Loadbalancer"

  validation {
    condition     = contains(["Loadbalancer", "UserDefinedRouting"], var.outbound_type)
    error_message = "Invalid 'outbound_type'. Only 'Loadbalancer' or 'UserDefinedRouting' are allowed."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID where the ARO cluster will be deployed. Required for authentication. Can be set via TF_VAR_subscription_id environment variable."
}

# NOTE: this is a required input as per the new ARO provider
#       https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster
variable "domain" {
  type        = string
  description = "Custom domain for the ARO cluster. If not specified, a random 8-character domain will be generated. Required for DNS policy restrictions when apply_restricted_policies is enabled."
  default     = null
  nullable    = true
}

variable "main_vm_size" {
  type        = string
  description = "Azure VM size for the ARO control plane nodes. Must meet ARO requirements. Example: Standard_D8s_v3, Standard_D16s_v3"
  default     = "Standard_D8s_v3"

  validation {
    condition     = var.main_vm_size != "" && var.main_vm_size != null
    error_message = "Invalid 'main_vm_size'. Must not be empty."
  }
}

variable "worker_vm_size" {
  type        = string
  description = "Azure VM size for the ARO worker nodes. Must meet ARO requirements. Example: Standard_D4s_v3, Standard_D8s_v3"
  default     = "Standard_D4s_v3"

  validation {
    condition     = var.worker_vm_size != "" && var.worker_vm_size != null
    error_message = "Invalid 'worker_vm_size'. Must not be empty."
  }
}

variable "worker_disk_size_gb" {
  type        = number
  default     = 128
  description = "Disk size in GB for the ARO worker node OS disks. Minimum 128GB required by ARO. Default: 128"

  validation {
    condition     = var.worker_disk_size_gb >= 128
    error_message = "Invalid 'worker_disk_size_gb'. Minimum of 128GB."
  }
}

variable "worker_node_count" {
  type        = number
  default     = 3
  description = "Number of worker nodes in the ARO cluster. Minimum 3 required by ARO. Default: 3"

  validation {
    condition     = var.worker_node_count >= 3
    error_message = "Invalid 'worker_node_count'. Minimum of 3."
  }
}

variable "apply_restricted_policies" {
  type        = bool
  default     = false
  description = "Apply additional Azure Policy restrictions to further limit permissions for service principals and identities. Recommended for production deployments. Default: false (permissive for development/example use)"
}

variable "jumphost_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to the SSH public key file for jumphost VM access. Default: ~/.ssh/id_rsa.pub. For CI/CD, set to a dummy file path or create a temporary key."
}

variable "jumphost_ssh_private_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "Path to the SSH private key file for jumphost VM access. Default: ~/.ssh/id_rsa. For CI/CD, set to a dummy file path or create a temporary key."
}
