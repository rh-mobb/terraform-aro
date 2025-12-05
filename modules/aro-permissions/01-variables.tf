variable "cluster_name" {
  type        = string
  description = "Name of the cluster to setup permissions for."
}

# NOTE: if using Terraform or other automation tool, use 'api' as the installation type.
variable "installation_type" {
  type        = string
  default     = "cli"
  description = "The installation type that will be used to create the ARO cluster.  One of: [api, cli]"

  validation {
    condition     = contains(["api", "cli"], var.installation_type)
    error_message = "'installation_type' must be one of: ['api', 'cli']."
  }
}

#
# service principals and users
#
variable "cluster_service_principal" {
  type = object({
    name   = string
    create = bool
  })
  default = {
    name   = null
    create = true
  }
  description = "Cluster Service Principal to use or optionally create.  If name is unset, the cluster_name is used to derive a name."
}

variable "installer_service_principal" {
  type = object({
    name   = string
    create = bool
  })
  default = {
    name   = null
    create = true
  }
  description = "Installer Service Principal to use or optionally create.  If name is unset, the cluster_name is used to derive a name.  Overridden if an 'installer_user_name' is specified."
}

variable "resource_provider_service_principal_name" {
  type        = string
  default     = "Azure Red Hat OpenShift RP"
  description = "ARO Resource Provider Service Principal name.  This will not change unless you are testing development use cases."
}

variable "installer_user" {
  type        = string
  default     = ""
  description = "User who will be executing the installation (e.g. via az aro create).  This overrides the 'installer_service_principal'.  Must be in UPN format (e.g. jdoe@example.com)."
}

#
# objects
#
variable "aro_resource_group" {
  type = object({
    name   = string
    create = bool
  })
  description = "ARO resource group to use or optionally create."
}

variable "vnet" {
  type        = string
  description = "VNET where ARO will be deployed into."
}

variable "vnet_resource_group" {
  type        = string
  default     = null
  description = "Resource Group where the VNET resides.  If unspecified, defaults to 'aro_resource_group.name'."
}

variable "managed_resource_group" {
  type        = string
  default     = null
  description = "Resource Group where the ARO object (managed resource group) resides."
}

variable "subnets" {
  type        = list(string)
  description = "Names of subnets used that belong to the 'vnet' variable.  Must be a child of the 'vnet'."
}

variable "route_tables" {
  type        = list(string)
  default     = []
  description = "Names of route tables for user-defined routing.  Route tables are assumed to exist in 'vnet_resource_group'."
}

variable "nat_gateways" {
  type        = list(string)
  default     = []
  description = "Names of NAT gateways for user-defined routing.  NAT gateways are assumed to exist in 'vnet_resource_group'."
}

variable "network_security_group" {
  type        = string
  default     = null
  description = "Network security group used in a BYO-NSG scenario."
}

variable "disk_encryption_set" {
  type        = string
  default     = null
  description = "Disk encryption set to use.  If specified, a role is created for allowing read access to the specified disk encryption set.  Must exist in 'aro_resource_group.name'."
}

#
# roles
#
variable "minimal_network_role" {
  type        = string
  default     = null
  description = "Role to manage to substitute for full 'Network Contributor' on network objects.  If specified, this is created, otherwise 'Network Contributor' is used.  For objects such as NSGs, route tables, and NAT gateways, this is used as a prefix for the role."
}

variable "minimal_aro_role" {
  type        = string
  default     = null
  description = "Role to manage to substitute for full 'Contributor' on the ARO resource group.  If specified, this is created, otherwise 'Contributor' is used.  For objects such as disk encryption sets, this is used as a prefix for the role."
}

#
# policy
#
variable "apply_network_policies_to_all" {
  type        = bool
  default     = false
  description = "Apply policies irrespective of object name.  This is helpful when you want to ensure all permissions are denied, irrespective of individual objects.  This is normal in scenarios where network objects are not grouped together (e.g. one VNET in a resource group) and there is no risk for denying something that may cause issues."
}

variable "apply_vnet_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict VNET permissions beyond what the role provides."
}

variable "apply_subnet_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict subnet permissions beyond what the role provides."
}

variable "apply_route_table_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict route table permissions beyond what the role provides."
}

variable "apply_nat_gateway_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict NAT gateway permissions beyond what the role provides."
}

variable "apply_nsg_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict NSG permissions beyond what the role provides."
}

variable "apply_dns_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict DNS permissions beyond what the role provides.  Must also specify 'var.managed_resource_group' to apply."
}

variable "apply_private_dns_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict DNS permissions beyond what the role provides.  Must also specify 'var.managed_resource_group' to apply."
}

variable "apply_public_ip_policy" {
  type        = bool
  default     = false
  description = "Apply Azure Policy to further restrict Public IP permissions beyond what the role provides.  Must also specify 'var.managed_resource_group' to apply."
}

#
# azure variables
#
variable "environment" {
  type        = string
  default     = "public"
  description = "Explicitly use a specific Azure environment.  One of: [public, usgovernment, dod]."

  validation {
    condition     = contains(["public", "usgovernment", "dod"], var.environment)
    error_message = "'environment' must be one of: ['public', 'usgovernment', 'dod']."
  }
}

variable "subscription_id" {
  type        = string
  description = "Explicitly use a specific Azure subscription id (defaults to the current system configuration)."
}

variable "tenant_id" {
  type        = string
  description = "Explicitly use a specific Azure tenant id (defaults to the current system configuration)."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region where region-specific objects exist or are to be created."
}

#
# other variables
#
variable "output_as_file" {
  type        = bool
  default     = true
  description = "Output created service principal client identifier and client secret into a source file."
}
