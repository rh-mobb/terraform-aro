# Summary

This Terraform module provides Azure permissions needed to install and manage ARO clusters using **managed identities** (preview feature).
Managed identities eliminate the need to manage service principal credentials and provide enhanced security for ARO cluster operations.

> **NOTE:** This module is for **managed identity-based deployments only** (currently in preview). For service principal deployments,
> use the [`aro-permissions`](../aro-permissions) module instead.

> **WARN:** Managed identities for ARO is currently a **preview feature** and not recommended for production use. This is a
> community-supported project and you should consult your appropriate product documentation prior to using this in your environment
> to ensure it is appropriate for your needs.

## Managed Identities

This module creates 9 user-assigned managed identities required for ARO cluster operations:

| Managed Identity | Purpose | Network Permissions |
|-----------------|---------|---------------------|
| `aro-service` | ARO operator | Subnets, Route Tables, NAT Gateways, NSG |
| `cloud-controller-manager` | Kubernetes cloud controller | Subnets, NSG |
| `cloud-network-config` | Network configuration | VNET, Subnets (required by ARO API) |
| `cluster` | Cluster identity (main) | N/A (manages other identities) |
| `disk-csi-driver` | Disk CSI driver | N/A |
| `file-csi-driver` | File CSI driver | VNET, Subnets, Route Tables, NAT Gateways, NSG (required by ARO API) |
| `image-registry` | Image registry | VNET, Subnets (required by ARO API) |
| `ingress` | Ingress controller | Subnets |
| `machine-api` | Machine API | Subnets, Route Tables, NSG |

The `cluster` managed identity acts as the primary identity and is assigned the "Managed Identity Operator" role on all other managed identities,
allowing it to manage them as needed.

## Objects

This section defines the objects which need individual permissions.

| Object Type | Description |
|------------|-------------|
| Subscription | The highest level a permission will be applied. Inherits down to all objects within that subscription. |
| ARO Resource Group | Resource group where the actual ARO object is created. |
| Managed Resource Group | Resource group where the underlying ARO objects (e.g. VMs, load balancers) are created. Created automatically by ARO service. |
| Network Resource Group | Resource group where network resources (e.g. VNET, NSG) exist. |
| VNET | VNET where the ARO cluster will be provisioned. |
| Subnets | Subnets within the VNET used by the ARO cluster (control plane and worker subnets). |
| Network Security Group | Network security group applied to the subnets (BYO-NSG scenarios). |
| Route Tables | Route tables for user-defined routing (if `outbound_type = UserDefinedRouting`). |
| NAT Gateways | NAT gateways for user-defined routing (if `outbound_type = UserDefinedRouting`). |

## Permissions

This section identifies what permissions are needed by each managed identity.

| Permission Number | Managed Identity | Object | Permission | Comment |
|-------------------|------------------|--------|------------|---------|
| 1 | `cloud-network-config` | VNET | Network Contributor or Minimal Network Permissions | |
| 2 | `file-csi-driver` | VNET | Network Contributor or Minimal Network Permissions | |
| 3 | `image-registry` | VNET | Network Contributor or Minimal Network Permissions | |
| 4 | `aro-service` | Subnets | Network Contributor or Minimal Network Permissions | |
| 5 | `cloud-controller-manager` | Subnets | Network Contributor or Minimal Network Permissions | |
| 6 | `cloud-network-config` | Subnets | Network Contributor or Minimal Network Permissions | Required by ARO API (not in script.sh but required) |
| 7 | `file-csi-driver` | Subnets | Network Contributor or Minimal Network Permissions | Required by ARO API (not in script.sh but required) |
| 8 | `image-registry` | Subnets | Network Contributor or Minimal Network Permissions | Required by ARO API (not in script.sh but required) |
| 9 | `ingress` | Subnets | Network Contributor or Minimal Network Permissions | |
| 10 | `machine-api` | Subnets | Network Contributor or Minimal Network Permissions | |
| 11 | `aro-service` | Route Tables | Network Contributor or Minimal Network Permissions | Only if route tables exist |
| 12 | `file-csi-driver` | Route Tables | Network Contributor or Minimal Network Permissions | Only if route tables exist |
| 13 | `machine-api` | Route Tables | Network Contributor or Minimal Network Permissions | Only if route tables exist |
| 14 | `aro-service` | NAT Gateways | Network Contributor or Minimal Network Permissions | Only if NAT gateways exist |
| 15 | `file-csi-driver` | NAT Gateways | Network Contributor or Minimal Network Permissions | Only if NAT gateways exist |
| 16 | `aro-service` | Network Security Group | Network Contributor or Minimal Network Permissions | Only if NSG exists |
| 17 | `cloud-controller-manager` | Network Security Group | Network Contributor or Minimal Network Permissions | Only if NSG exists |
| 18 | `file-csi-driver` | Network Security Group | Network Contributor or Minimal Network Permissions | Only if NSG exists |
| 19 | `machine-api` | Network Security Group | Network Contributor or Minimal Network Permissions | Only if NSG exists |
| 20 | `cluster` | Other Managed Identities | Managed Identity Operator | Allows cluster identity to manage other identities |
| 21 | Installer (current user) | ARO Resource Group | Contributor | Required for cluster deployment |
| 22 | Resource Provider SP | VNET | Network Contributor or Minimal Network Permissions | |
| 23 | Resource Provider SP | Route Tables | Network Contributor or Minimal Network Permissions | Only if route tables exist |
| 24 | Resource Provider SP | NAT Gateways | Network Contributor or Minimal Network Permissions | Only if NAT gateways exist |
| 25 | Resource Provider SP | Network Security Group | Network Contributor or Minimal Network Permissions | Only if NSG exists |

### Minimal Network Permissions

In many cases, such as separation of duties and where network teams must provide infrastructure to consume, a
reduced permission set lower than [Network Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#network-contributor) is required.

The following permissions, in place of Network Contributor, have been successful. Note that managed identities use a union of
static permissions with built-in role permissions, so write permissions are not always required:

**VNET Permissions:**
- `Microsoft.Network/virtualNetworks/join/action`
- `Microsoft.Network/virtualNetworks/read`

**Subnet Permissions:**
- `Microsoft.Network/virtualNetworks/subnets/join/action`
- `Microsoft.Network/virtualNetworks/subnets/read`
- `Microsoft.Network/virtualNetworks/subnets/write`

**Route Table Permissions (if route tables exist):**
- `Microsoft.Network/routeTables/join/action`
- `Microsoft.Network/routeTables/read`

**NAT Gateway Permissions (if NAT gateways exist):**
- `Microsoft.Network/natGateways/join/action`
- `Microsoft.Network/natGateways/read`

**Network Security Group Permissions (if NSG exists):**
- `Microsoft.Network/networkSecurityGroups/join/action`

## Module Design

This module follows MOBB RULES best practices:

- **Simplicity**: Uses explicit role assignments instead of complex loops
- **Explicit over Clever**: Each managed identity has individual role assignment resources
- **Modern Terraform**: Uses `for_each` for subnet/route table/NAT gateway assignments
- **No Legacy Code**: Providers are inherited from caller (no provider blocks in module)

## Prereqs

Prior to running this module, the following must be satisfied:

1. Must be logged in as an administrator user using the `az login` command. Because assigning permissions is an administrative task,
   it is assumed whomever is running this module is an administrator. Alternative to full tenant administrator permissions, a user that has the
   [User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator)
   role should be able to complete this task.

1. Must have a VNET architecture pre-deployed and used as an input.

1. Must have the ARO Resource Provider registered:
   ```bash
   az provider register -n Microsoft.RedHatOpenShift --wait
   ```

## Usage

```hcl
module "aro_managed_identity_permissions" {
  source = "./modules/aro-managed-identity-permissions"

  cluster_name = "my-aro-cluster"
  location     = "eastus"

  aro_resource_group = {
    name   = "my-aro-rg"
    create = false
  }

  vnet                = "my-vnet"
  vnet_resource_group = "my-vnet-rg"
  subnets             = ["control-plane-subnet", "worker-subnet"]
  route_tables        = ["my-route-table"]  # Optional, if using UserDefinedRouting
  nat_gateways        = []                  # Optional, if using NAT gateways
  network_security_group = "my-nsg"         # Optional, for BYO-NSG scenarios

  minimal_network_role = "my-aro-network"  # Optional, for minimal permissions

  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id

  enabled = true
}
```

## Outputs

The module provides the following outputs:

- `managed_identity_ids`: Map of managed identity names to their Azure resource IDs
- `managed_identity_principal_ids`: Map of managed identity names to their principal IDs (used in ARM templates)

These outputs are used by the ARO cluster deployment (via ARM template) to configure the `platformWorkloadIdentityProfile` and `identity` blocks.

## Related Documentation

- [Microsoft Documentation: Create ARO cluster with managed identities](https://learn.microsoft.com/en-us/azure/openshift/howto-create-openshift-cluster?pivots=aro-deploy-az-cli)
- [ARO Permissions Module (Service Principals)](../aro-permissions/README.md)
