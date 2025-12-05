variable "cluster_name" {
  type        = string
  description = "Name of the cluster to setup permissions for."
}

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

variable "minimal_network_role" {
  type        = string
  default     = null
  description = "Role to manage to substitute for full 'Network Contributor' on network objects.  If specified, this is created, otherwise 'Network Contributor' is used."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region where region-specific objects exist or are to be created."
}

variable "environment" {
  type        = string
  default     = "public"
  description = "Explicitly use a specific Azure environment.  One of: [public, usgovernment, dod]."

  validation {
    condition     = contains(["public", "usgovernment", "dod"], var.environment)
    error_message = "'environment' must be one of: ['public', 'usgovernment', 'dod']."
  }
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Enable creation of managed identity resources. When false, module creates no resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all managed identity resources."
}
