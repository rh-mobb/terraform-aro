# Summary

This Terraform module provides Azure permissions needed to install and manage ARO clusters using **service principals**.
The problem we see in the field is that there are overlapping identities that need specific permission sets, which often
results in incorrect permissions and makes for a confusing experience.

> **NOTE:** This module is for **service principal-based deployments only**. For managed identity deployments (preview),
> use the [`aro-managed-identity-permissions`](../aro-managed-identity-permissions) module instead.

> **WARN:** It should be noted that certain product changes will force this to change.  This is a community-supported
project and you should consult your appropriate product documentation prior to using this in your environment
to ensure it is appropriate for your needs.

## Identities

This section identifies the individual identities that need ARO permissions.  These identities will be used
in verbiage when describing what permissions are needed.

> **NOTE:** the **Install Flags** column helps to associate these service principals to actual ARO installation flags
> using the CLI.

| Identity | Type | Install Flags | Description |
| ---- | ---- | ---- | ---- |
| Cluster Service Principal | Service Principal | `--client-id` and `--client-secret` | Runs all operations in the cluster and that interacts with the Azure API as part of operations within the cluster. Cluster Autoscaler and the Service Controller for Azure are two key components which leverage these credentials. |
| Installer | User or Service Principal | N/A | Whomever the installation process is run as.  This may be a user account or a service principal.  This is who is logged in using the `az login` command. |
| Resource Provider Service Principal | Service Principal | N/A | Azure Resource Provider that represents ARO.  This is automatically created in the account when first running the setup step `az provider register -n Microsoft.RedHatOpenShift --wait`.  This service principal can be found by running `az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'"`. |


## Objects

This section defines the objects which need individual permissions.

> **NOTE:** the **Install Flags** column helps to associate these objects to actual ARO installation flags
> using the CLI.

| Object Type | Install Flags | Description |
| ---- | ---- | ---- |
| Subscription | `--subscription` | The highest level a permission will be applied.  Inherits down to all objects within that subscription.  This is not a mandatory flag and the subscription may be set based on how a user has logged in with `az login`. |
| ARO Resource Group | `--resource-group` | Resource group in the above subscription where the actual ARO object is created. |
| Managed Resource Group | `--cluster-resource-group` | Resource group in the above subscription where the underlying ARO objects (e.g. VMs, load balancers) are created.  This is created automatically as part of provisioning and is managed by the ARO service itself. |
| Network Resource Group | `--vnet-resource-group` | Resource group in the above subscription where network resources (e.g. VNET, NSG) exist.  Some organizations will use the Managed Resource Group for this purpose as well and do not need a dedicated Network Resource Group. |
| VNET | `--vnet`| VNET where the ARO cluster will be provisioned. |
| Network Security Group | N/A | Only required for BYO-NSG scenarios.  Network security group, applied to the subnets.  This is is pre-applied by the user to the subnets prior to installation. |
| Disk Encryption Set | `--disk-encryption-set` | The disk encryption set used to encrypt master and worker node disks. |


## Permissions

This section identifies what permissions are needed by each individual identity.

> NOTE: row numbers are used to indicate in the code where permissions are aligned.

| Permission Number | Identity | Object | Permission | Comment |
| ---- | ---- | ---- | ---- | ---- |
| 1 | [Cluster Service Principal](#identities) | [VNET](#objects) | [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) or [Minimal Network Permissions](#minimal-network-permissions) | |
| 2 | [Cluster Service Principal](#identities) | [Network Security Group](#objects) | [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) or [Minimal Network Permissions](#minimal-network-permissions) | Only needed if BYO-NSG is pre-attached to the subnet. |
| 3 | [Cluster Service Principal](#identities) | [ARO Resource Group](#objects) | [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) | |
| 4 | [Cluster Service Principal](#identities) | [Disk Encryption Set](#objects) | [Other](#other-permissions) | |
| 5 | [Installer](#identities) | [ARO Resource Group](#objects) | [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) or [Minimal ARO Permissions](#minimal-aro-permissions) | |
| 6 | [Installer](#identities) | [Network Resource Group](#objects)| [Reader](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader) | Only required if `az aro create` is used to install. |
| 7 | [Installer](#identities) | [Subscription](#objects) | [User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator) | Only required if `az aro create` is used to install. |
| 8 | [Installer](#identities) | Azure AD | [Directory Readers](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#directory-readers) | Only required if `az aro create` is used to install. |
| 9 | [Installer](#identities) | [VNET](#objects) | [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) or [Minimal Network Permissions](#minimal-network-permissions) | Only required if `az aro create` is used to install. |
| 10 | [Resource Provider Service Principal](#identities) | [VNET](#objects) | [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) or [Minimal Network Permissions](#minimal-network-permissions) | |
| 11 | [Resource Provider Service Principal](#identities) | [Network Security Group](#objects) | [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) or [Minimal Network Permissions](#minimal-network-permissions) | |
| 12 | [Resource Provider Service Principal](#identities) | [Disk Encryption Set](#objects) | [Other](#other-permissions) | |
| 13 | [Resource Provider Service Principal](#identities) | [Managed Resource Group](#objects) | [Owner](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) | This permission does not need to pre-exist.  It is applied when the Resource Provider Service Principal creates the resource group as part of installation.  This is for documentation purposes only. |


### Minimal Network Permissions

In many cases, such as separation of duties and where network teams must provide infrastructure to consume, a
reduced permission set lower than [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) is required.  This is possible, however it should be noted that [product documentation](https://learn.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#verify-your-permissions) indicates higher permissions and the product will
be developed against that assumption unless otherwise noted.

The following permission, in place of Network Contributor, have been successful (including links to the code which
validates the permissions).  The VNET this applies to equates to the value of the `--vnet` flag in the `az aro create` command:

Needed always:

* [Microsoft.Network/virtualNetworks/join/action](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/virtualNetworks/read](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/virtualNetworks/write](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/virtualNetworks/subnets/join/action](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/virtualNetworks/subnets/read](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/virtualNetworks/subnets/write](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L221-L226)
* [Microsoft.Network/networkSecurityGroups/join/action](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L846)

Needed when provided VNET subnets have route table(s) attached:

* [Microsoft.Network/routeTables/join/action](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L301-L303)
* [Microsoft.Network/routeTables/read](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L301-L303)
* [Microsoft.Network/routeTables/write](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L301-L303)


Needed when provided VNET subnets have NAT gateway(s) attached:

* [Microsoft.Network/natGateways/join/action](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L367-L369)
* [Microsoft.Network/natGateways/read](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L367-L369)
* [Microsoft.Network/natGateways/write](https://github.com/Azure/ARO-RP/blob/v20231110.00/pkg/validate/dynamic/dynamic.go#L367-L369)


### Minimal ARO Permissions

In addition to minimizing network permissions, the installer role may need minimal permissions as well.  These permissions are as follows:

* Microsoft.RedHatOpenShift/openShiftClusters/read
* Microsoft.RedHatOpenShift/openShiftClusters/write
* Microsoft.RedHatOpenShift/openShiftClusters/delete
* Microsoft.RedHatOpenShift/openShiftClusters/listCredentials/action
* Microsoft.RedHatOpenShift/openShiftClusters/listAdminCredentials/action


### Other Permissions

In addition to the above, the following other permissions may be needed by specific identities:

* [Microsoft.Compute/diskEncryptionSets/read](https://github.com/Azure/ARO-RP/blob/v20240503.00/pkg/validate/dynamic/diskencryptionset.go#L78)


### Azure Policy

Users may wish to further restrict required minimal permissions above with Azure Policy.  Below are the
list of permissions that may be limited and any known limitations when doing so.  See the [apply_*_policy](variables.tf) variables to see what is known to be able to be further limited.

| Permissions                                               | Known Limitations                                               |
| --------------------------------------------------------- | --------------------------------------------------------------- |
| Microsoft.Network/virtualNetworks/join/action             | - Must have `outbound_type` == `UserDefinedRouting`.            |
| Microsoft.Network/virtualNetworks/write                   | - Must have `outbound_type` == `UserDefinedRouting`.            |
| Microsoft.Network/virtualNetworks/subnets/join/action     | - Must have `outbound_type` == `UserDefinedRouting`.            |
| Microsoft.Network/virtualNetworks/subnets/write           | - `subnets/write` still need [this](https://github.com/Azure/ARO-RP/pull/4087) merged and deployed before we can limit it  <br>
|                                                           | - [No ability to dynamically create private link endpoint](https://github.com/kubernetes-sigs/azurefile-csi-driver/blob/master/docs/driver-parameters.md) with File Services operator with `networkEndpointType` parameter  <br>
|                                                           | - No ability to ensure NSG to subnet attachment (likely not applicable in BYO-NSG scenarios).  <br>
|                                                           | - Must have `Microsoft.ContainerRegistry` and `Microsoft.Storage` service endpoints set on the subnet.  <br>
|                                                           | - Must have network policy for private endpoints set to `Disabled`. |
| Microsoft.Network/routeTables/join/action                 | - Must have `outbound_type` == `UserDefinedRouting`.                |
| Microsoft.Network/routeTables/write                       | - Must have `outbound_type` == `UserDefinedRouting`.                |
| Microsoft.Network/natGateways/join/action                 | - Must have `outbound_type` == `UserDefinedRouting`.                |
| Microsoft.Network/natGateways/write                       | - Must have `outbound_type` == `UserDefinedRouting`.                |
| Microsoft.Network/publicIPAddresses/write                 | - Must have `private` for both Ingress and API profiles.            |
| Microsoft.Network/publicIPAddresses/delete                | - Must have `private` for both Ingress and API profiles.            |
| Microsoft.Network/dnsZones/A/write                        | - Must have `domain` defined (BYO-domain).                          |
| Microsoft.Network/dnsZones/A/delete                       | - Must have `domain` defined (BYO-domain).                          |
| Microsoft.Network/privateDnsZones/A/write                 | - Must have `domain` defined (BYO-domain).                          |
| Microsoft.Network/privateDnsZones/A/delete                | - Must have `domain` defined (BYO-domain).                          |


## Module Scope

This module handles **service principal-based ARO deployments only**. It creates and configures:

- **Cluster Service Principal**: Used by the ARO cluster to interact with Azure APIs
- **Installer Service Principal**: Used during cluster installation (for API installation type)
- **Role Assignments**: Assigns necessary permissions to service principals
- **Custom Roles**: Optionally creates minimal permission roles (if `minimal_network_role` is specified)
- **Azure Policies**: Optionally applies restrictive policies (if `apply_*_policy` variables are enabled)

For **managed identity deployments** (currently in preview), use the [`aro-managed-identity-permissions`](../aro-managed-identity-permissions) module instead.

## Prereqs

Prior to running this module, the following must be satisfied:

1. Must be logged in as an administrator user using the `az login` command.  Because assigning permissions is an administrative task,
it is assumed whomever is running this module is an administrator.  Alternative to full tenant administrator permissions, a user that has the
[User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator)
role should be able to complete this task.

1. Must have the `az` CLI installed and configured locally.  There are some external commands ran in this module which makes this
necessary.  It is not ideal but it works for now.

1. Must have the `jq` CLI installed locally.  There are some external commands ran in this module which makes this
necessary.  It is not ideal but it works for now.

1. Must have a VNET architecture pre-deployed and used as an input.


## Examples

Examples of how to use this module are located in the examples directory.  The examples thus far are:

1. When ARO will be installed with the Azure `az` CLI - [examples/cli](https://github.com/rh-mobb/terraform-aro-permissions/blob/main/examples/cli/main.tf)
2. When ARO will be installed with an automation tool like Terraform (using the Microsoft API) - [examples/api](https://github.com/rh-mobb/terraform-aro-permissions/tree/main/examples/api)
