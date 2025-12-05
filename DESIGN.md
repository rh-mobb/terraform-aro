# Project Design Document

**Project:** Terraform ARO Cluster Deployment
**Version:** 0.1.0
**Last Updated:** 2024-12-01

## Project Intent

This project provides Terraform infrastructure-as-code for deploying Azure Red Hat OpenShift (ARO) clusters on Azure. The primary goal is to provide a reusable, well-documented Terraform module that supports both public and private ARO cluster deployments with configurable security options.

## High-Level Architecture

### Core Components

1. **ARO Cluster** (`50-cluster.tf`)
   - Azure Red Hat OpenShift cluster resource
   - Configurable control plane and worker node profiles
   - Supports public and private API/ingress visibility
   - Conditional deployment: Service Principal (default) or Managed Identities (preview)
   - Managed identities use ARM template deployment (`azurerm_resource_group_template_deployment`)

2. **Networking** (`10-network.tf`)
   - Virtual network with CIDR blocks for ARO
   - Control plane subnet (10.0.0.0/23)
   - Machine/worker subnet (10.0.2.0/23)
   - Network Security Groups (NSGs) with permissive defaults
   - Service endpoints for Storage and Container Registry

3. **Identity & Access Management** (`20-iam.tf`)
   - Service principal management via vendored `terraform-aro-permissions` module (v0.2.1)
   - Module located at `./modules/aro-permissions/`
   - Installer and cluster service principals (default)
   - Managed identities support (preview feature, enabled via `enable_managed_identities` variable)
   - When managed identities enabled: Creates 9 user-assigned managed identities
   - Minimal permission roles
   - Optional Azure Policy restrictions

4. **Egress Traffic Control** (`11-egress.tf`) - Conditional
   - Azure Firewall for restricting egress traffic
   - Firewall subnet (10.0.6.0/23)
   - Route tables for User Defined Routing
   - Network and application rule collections
   - Enabled via `restrict_egress_traffic` variable

5. **Jumphost** (`30-jumphost.tf`) - Conditional
   - Linux VM for accessing private clusters
   - Jumphost subnet (10.0.4.0/23)
   - Public IP for SSH access
   - Pre-installed OpenShift CLI tools
   - Created when API or ingress profile is Private

6. **Azure Container Registry** (`40-acr.tf`) - Conditional
   - Private ACR with private endpoint
   - Private endpoint subnet (10.0.8.0/23)
   - Private DNS zone integration
   - Enabled via `acr_private` variable

## Design Decisions

### 1. Security Defaults (Permissive)

**Decision:** Security defaults are permissive to prioritize usability for examples, demos, and development environments.

**Rationale:**
- Makes the codebase easier to use for learning and testing
- Reduces friction for developers getting started
- Aligns with context-aware application philosophy

**Implementation:**
- NSG rules allow `0.0.0.0/0` for API, HTTP, and HTTPS (TODO comments indicate need for lockdown)
- Firewall network rules allow all traffic when egress restriction is enabled
- Jumphost NSG allows SSH from any source (`*`)

**Production Hardening:**
- Restrict NSG source addresses to specific IP ranges
- Implement strict firewall rules with specific destinations
- Use Azure Policy for additional restrictions (`apply_restricted_policies`)

### 2. Conditional Resources

**Decision:** Use conditional resources (count/conditional creation) for optional components.

**Rationale:**
- Reduces resource costs when features aren't needed
- Allows flexible deployment scenarios
- Simplifies codebase by avoiding separate modules

**Components:**
- Firewall: Created when `restrict_egress_traffic = true`
- Jumphost: Created when API or ingress profile is Private
- ACR: Created when `acr_private = true`

### 3. Service Principal Management

**Decision:** Use vendored `terraform-aro-permissions` module (v0.2.1) for service principal creation and permissions.

**Rationale:**
- Separates concerns (IAM vs infrastructure)
- Reuses proven module with minimal permissions
- Simplifies permission management
- Self-contained repository (no external git dependencies)
- Faster terraform init (no git clone required)

**Implementation:**
- Module vendored in `./modules/aro-permissions/`
- Original source: `https://github.com/rh-mobb/terraform-aro-permissions.git?ref=v0.2.1`
- Module creates installer and cluster service principals
- Uses custom roles with minimal required permissions
- Supports optional Azure Policy restrictions

### 4. Managed Identities Support (Preview)

**Decision:** Support Azure Red Hat OpenShift managed identities via ARM template deployment.

**Rationale:**
- Managed identities provide enhanced security (no credential management)
- Follows Azure best practices for identity management
- Required for future-proofing as managed identities become GA
- Leverages existing aro-permissions module support for managed identities

**Implementation:**
- Feature flag: `enable_managed_identities` (default: false)
- When enabled: aro-permissions module creates 9 user-assigned managed identities
- Cluster deployment uses ARM template (`azurerm_resource_group_template_deployment`)
- ARM template uses API version `2024-08-12-preview` (required for managed identities)
- ARM template includes `platformWorkloadIdentityProfile` and `identity` blocks
- Role assignments between managed identities handled by ARM template
- Outputs work identically for both service principal and managed identity deployments

**Limitations:**
- Currently in tech preview (not recommended for production)
- Requires ARM template deployment (Terraform resource doesn't support it yet)
- Existing clusters cannot be migrated from service principals to managed identities

### 5. File Organization

**Decision:** Organize Terraform code by resource type/functionality into separate files.

**Rationale:**
- Improves code readability and maintainability
- Makes it easier to find specific resources
- Follows common Terraform patterns

**Structure:**
- `00-terraform.tf` - Provider configuration
- `01-variables.tf` - Variable definitions
- `10-network.tf` - Core networking resources (VNet, subnets, NSGs)
- `11-egress.tf` - Firewall and egress control
- `20-iam.tf` - Identity and access management
- `30-jumphost.tf` - Jumphost VM
- `40-acr.tf` - Azure Container Registry
- `50-cluster.tf` - ARO cluster resource

### 5. Naming Conventions

**Decision:** Use consistent naming with `local.name_prefix` (cluster name) as prefix.

**Rationale:**
- Ensures unique resource names
- Makes resources easily identifiable
- Follows Azure naming best practices

**Pattern:**
- Resources: `${local.name_prefix}-<resource-type>-<identifier>`
- Example: `my-aro-cluster-rg`, `my-aro-cluster-vnet`

### 6. Tagging Strategy

**Decision:** Use default tags with environment and owner, allow override via `tags` variable.

**Rationale:**
- Provides consistent resource tagging
- Supports cost management and organization
- Allows customization per deployment

**Default Tags:**
- `environment = "development"`
- `owner = "your@email.address"`
- `ManagedBy = "Terraform"` (added per MOBB RULES)

## Constraints and Assumptions

### Constraints

1. **Azure Provider Version:** Requires `azurerm` provider `~>4.21.1`
2. **ARO Requirements:** Must meet Azure Red Hat OpenShift prerequisites
3. **Service Principal Permissions:** Requires permissions to create service principals and assign roles
4. **Network CIDR Blocks:** Must not overlap with existing Azure networks
5. **Domain:** Optional but required for DNS policy restrictions

### Assumptions

1. **SSH Keys:** Jumphost assumes SSH keys exist at `~/.ssh/id_rsa.pub` and `~/.ssh/id_rsa`
2. **Pull Secret:** Optional Red Hat pull secret for private registries
3. **Azure CLI:** Users have Azure CLI configured and authenticated
4. **Terraform State:** State management handled externally (not in scope)
5. **Resource Group:** Can create or use existing resource group

## Non-Goals

1. **Multi-Region Deployment:** Single region deployments only
2. **Hub-Spoke Architecture:** Current design uses single VNet (TODO: convert to hub-spoke)
3. **Custom Node Pools:** Standard control plane and worker profiles only
4. **Advanced Networking:** No support for custom DNS, VPN, or ExpressRoute
5. **Monitoring/Logging:** Observability setup not included
6. **Backup/Disaster Recovery:** Backup and DR strategies not included
7. **CI/CD Integration:** Deployment automation not included

## Future Considerations

### Planned Improvements

1. **Hub-Spoke Architecture:** Convert from single VNet to hub-spoke model (noted in `11-egress.tf`)
2. **Security Hardening:** Implement restricted NSG rules for private clusters (TODO comments in `10-network.tf`)
3. **Firewall Rules:** Restrict firewall network rules (TODO in `11-egress.tf`)
4. **Testing:** Add Terraform validation tests and CI/CD integration

### Potential Enhancements

1. **Multi-Region Support:** Extend to support multi-region deployments
2. **Custom Node Pools:** Support for additional worker node pools
3. **Monitoring Integration:** Add Azure Monitor and Log Analytics
4. **Backup Strategy:** Implement backup and restore capabilities
5. **Documentation:** Expand with more examples and use cases

## Context-Aware Application

### Project Context

This project serves as an **example/demo/development** tool for deploying ARO clusters. As such:

- **Security defaults are permissive** to prioritize usability and learning
- **Security features are toggleable** (e.g., `restrict_egress_traffic`, `apply_restricted_policies`)
- **Documentation includes production hardening guidance** (this document, README)

### Security Considerations

**Current State (Example/Demo):**
- Permissive NSG rules (allow from `0.0.0.0/0`)
- Optional egress restriction (disabled by default)
- Optional Azure Policy restrictions (disabled by default)
- Jumphost allows SSH from any source

**Production Hardening Required:**
- Restrict NSG source addresses to specific IP ranges
- Enable and configure strict firewall rules
- Enable Azure Policy restrictions
- Restrict jumphost SSH access to specific IPs
- Implement network security best practices
- Review and restrict all security group rules

## References

- [Azure Red Hat OpenShift Documentation](https://learn.microsoft.com/en-us/azure/openshift/)
- [Terraform ARO Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster)
- [terraform-aro-permissions Module](https://github.com/rh-mobb/terraform-aro-permissions) (vendored at `./modules/aro-permissions/` - v0.2.1)
- [ARO Egress Restriction Guide](https://learn.microsoft.com/en-us/azure/openshift/howto-restrict-egress)
- [ARO Private Cluster Guide](https://learn.microsoft.com/en-us/azure/openshift/howto-create-private-cluster-4x)
