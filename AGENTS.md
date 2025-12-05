# Terraform ARO - Best Practices

**Project:** Terraform ARO Cluster Deployment
**Last Updated:** 2024-12-01

This document compiles best practices from MOBB RULES (Managed OpenShift Black Belts - ReUsable Library for Expert Systems) specifically for this Terraform ARO deployment project.

## Project Context

- **Cloud:** Azure
- **Platform:** ARO (Azure Red Hat OpenShift)
- **Languages:** Terraform (HCL)
- **Design:** See [DESIGN.md](./DESIGN.md) for project intent and architecture
- **Plan:** See [PLAN.md](./PLAN.md) for implementation tasks and progress

## Philosophy

Following MOBB RULES core principles:

- **Simplicity over Complexity:** Favor straightforward, maintainable solutions over clever abstractions
- **WET over DRY:** Write Everything Twice before abstracting; duplication improves clarity
- **Context-Aware Application:** Apply rules based on project purpose (example/demo/dev/staging/production)

## Design Alignment

This project follows the design outlined in DESIGN.md. All practices below support the project's intent:

- **Primary Purpose:** Example/demo/development tool for deploying ARO clusters
- **Security Approach:** Permissive defaults with toggleable security features
- **Design Constraints:** Single-region, single VNet, standard node profiles
- **Non-Goals:** Multi-region, hub-spoke, custom node pools, monitoring/backup

## Terraform Standards

### File Organization

- **Current Pattern:** Organize with numeric prefixes per MOBB RULES
  - `00-terraform.tf` - Provider configuration
  - `01-variables.tf` - Variable definitions
  - `10-network.tf` - Core networking resources (VNet, subnets, NSGs)
  - `11-egress.tf` - Firewall and egress control
  - `20-iam.tf` - Identity and access management
  - `30-jumphost.tf` - Jumphost VM
  - `40-acr.tf` - Azure Container Registry
  - `50-cluster.tf` - ARO cluster resource

- **Status:** ✅ Files organized with numeric prefixes per MOBB RULES standards
- **Note:** Numeric prefixes help with dependency ordering and logical grouping

### Variable Definitions

- **All variables must have descriptions**
- **Use appropriate types** (string, number, bool, map, list)
- **Provide sensible defaults** where appropriate
- **Use validation blocks** for constrained values
- **Mark optional variables with `nullable = true`** or `default = null`

**Current Status:** ✅ All variables have descriptions. Some optional variables use `default = null` (good practice).

### Output Definitions

- **All outputs must have descriptions**
- **Document what each output provides**
- **Include usage examples where helpful**

**Current Status:** ✅ All outputs have descriptions.

### Resource Naming

- **Use consistent naming patterns**
- **Use `local.name_prefix` for resource prefixes**
- **Follow Azure naming conventions** (lowercase, hyphens)

**Current Pattern:**
- Resources: `${local.name_prefix}-<resource-type>-<identifier>`
- Example: `my-aro-cluster-rg`, `my-aro-cluster-vnet`

**Status:** ✅ Consistent naming pattern in use.

### Code Style

- **Use `terraform fmt`** to ensure consistent formatting
- **Run `terraform validate`** before committing
- **Use meaningful comments** for complex logic
- **Document TODOs** with context

**Current Status:**
- Code is generally well-formatted
- TODO comments present (documented in DESIGN.md)
- Some comments could be expanded

### Provider Configuration

- **Pin provider versions** to avoid unexpected changes
- **Use provider aliases** when multiple configurations needed
- **Document provider requirements**

**Current Status:** ✅ Provider version pinned (`~>4.21.1`), aliases used appropriately.

## Azure Standards

### Resource Naming

- **Use lowercase with hyphens** (Azure standard)
- **Keep names under 64 characters** where possible
- **Use consistent prefixes** for resource groups

**Current Pattern:** ✅ Follows Azure naming conventions.

### Tagging

- **Apply tags consistently** to all resources
- **Include required tags:** `environment`, `owner`, `ManagedBy`
- **Allow tag customization** via variables

**Current Tags:**
- `environment = "development"` (default)
- `owner = "your@email.address"` (default)
- `ManagedBy = "Terraform"` (added per MOBB RULES)

**Status:** ✅ Tags applied consistently.

### Security Groups

- **Document security considerations** when using permissive rules
- **Provide examples** for production hardening
- **Make security configurable** via variables

**Current Status:**
- ⚠️ NSG rules are permissive (0.0.0.0/0) - documented in DESIGN.md
- ⚠️ TODO comments indicate need for lockdown
- ✅ Security is toggleable (`restrict_egress_traffic`, `apply_restricted_policies`)

### Service Principals

- **Use minimal permissions** (principle of least privilege)
- **Separate installer and cluster service principals**
- **Use custom roles** with minimal required permissions

**Current Status:** ✅ Uses vendored `terraform-aro-permissions` module (v0.2.1) with minimal permissions. Module located at `./modules/aro-permissions/`.

## ARO Platform Standards

### Cluster Configuration

- **Support both public and private clusters**
- **Use appropriate outbound types** (LoadBalancer vs UserDefinedRouting)
- **Configure network profiles** correctly (pod CIDR, service CIDR)
- **Enable preconfigured NSG** for ARO-managed security groups

**Current Status:** ✅ Supports public/private, configurable outbound types.

### Network Requirements

- **Use dedicated subnets** for control plane and workers
- **Configure service endpoints** (Storage, ContainerRegistry)
- **Disable private endpoint network policies** on ARO subnets
- **Use appropriate CIDR blocks** (non-overlapping)

**Current Status:** ✅ Proper subnet configuration, service endpoints configured.

### Egress Traffic Control

- **Support egress restriction** via Azure Firewall
- **Configure route tables** for User Defined Routing
- **Document required firewall rules** for ARO operation
- **Make egress restriction toggleable**

**Current Status:**
- ✅ Egress restriction supported and toggleable
- ⚠️ Firewall rules are permissive (allow-all) - documented in DESIGN.md
- ✅ Application rules configured for ARO requirements

### Private Cluster Access

- **Provide jumphost** for private cluster access
- **Pre-install OpenShift CLI tools** on jumphost
- **Document connectivity procedures**

**Current Status:** ✅ Jumphost created conditionally with pre-installed tools.

## Context-Aware Application

### Project Context: Example/Demo/Development

This project serves as an example/demo tool. Security standards are applied contextually:

**Current Security Approach:**
- ✅ **Permissive defaults** - Prioritize usability and learning
- ✅ **Toggleable security** - Allow enabling strict controls
- ✅ **Documented trade-offs** - Clear guidance on production hardening
- ✅ **Context-aware** - Relaxed for examples, strict for production

**Security Features:**
- `restrict_egress_traffic` - Toggle egress restriction (default: false)
- `apply_restricted_policies` - Toggle Azure Policy restrictions (default: false)
- NSG rules - Permissive by default, documented for hardening

**Production Hardening Required:**
- Restrict NSG source addresses
- Enable strict firewall rules
- Enable Azure Policy restrictions
- Restrict jumphost SSH access
- Review all security group rules

### Security Documentation

**Current State:**
- Security considerations documented in DESIGN.md
- README includes usage instructions
- TODO comments indicate security improvements needed

**Best Practice:**
- ⚠️ **Security Note:** This example uses permissive security defaults for development and learning purposes. For production deployments:
  - Set `restrict_egress_traffic = true`
  - Set `apply_restricted_policies = true`
  - Restrict NSG source addresses to specific IP ranges
  - Review and restrict firewall rules
  - Implement network security best practices

## Project-Specific Rules

### Existing Patterns (Preserved)

1. **File Organization:** Flat structure by resource type (acceptable for project size)
2. **Naming Convention:** `${local.name_prefix}-<resource-type>-<identifier>`
3. **Conditional Resources:** Use `count` for optional components
4. **Service Principal Management:** Vendored module (`./modules/aro-permissions/` - terraform-aro-permissions v0.2.1)
5. **Tagging:** Default tags with override capability

### Legacy Exceptions

**None identified.** All code follows current best practices or has documented TODOs for improvement.

### Deviations from MOBB RULES

**None significant.** Project aligns with MOBB RULES standards. Minor deviations:

1. **File Organization:** Uses flat structure instead of numeric prefixes
   - **Rationale:** Project size doesn't warrant numeric prefixes
   - **Status:** Acceptable per MOBB RULES (simplicity over complexity)

2. **Security Defaults:** Permissive security rules
   - **Rationale:** Example/demo context - documented and toggleable
   - **Status:** Aligns with context-aware application principle

## Rule Hierarchy

Priority order for applying rules:

1. **DESIGN.md intent** (highest priority - defines project boundaries)
2. **Project context** (example/dev/staging/prod) - determines strictness
3. **Project-specific rules** (this section)
4. **Platform rules** (ARO standards)
5. **Cloud rules** (Azure standards)
6. **Language rules** (Terraform standards - foundational)

## Makefile Standards

### Required Targets

- `help` - Show available targets
- `init` - Initialize Terraform
- `validate` - Run `terraform validate`
- `fmt` - Check formatting
- `fmt-fix` - Fix formatting
- `check` - Run validation and formatting checks
- `lint` - Run linting (if available)

**Current Status:** ✅ Makefile includes standard targets.

## Versioning Standards

### Semantic Versioning

This project follows [Semantic Versioning (SemVer)](https://semver.org/) format: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.0.0): Breaking changes (renamed variables, changed types, removed features)
- **MINOR** (0.2.0): New features (new variables/outputs, backward-compatible additions)
- **PATCH** (0.1.1): Bug fixes (fixes, documentation updates)

### Version Management

- **CHANGELOG.md**: Documents all changes following Keep a Changelog format
- **Git Tags**: Use annotated tags for releases (`git tag -a v0.1.0 -m "Release message"`)
- **PLAN.md**: Tracks project version
- **GitHub Releases**: Optional but recommended for distribution

### Release Process

When releasing a new version:

1. Run `make test` to ensure all tests pass
2. Update CHANGELOG.md - move `[Unreleased]` content to version section
3. Update version links in CHANGELOG.md
4. Update PLAN.md version if applicable
5. Commit changes: `git commit -m "chore: prepare release vX.Y.Z"`
6. Create annotated tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z: Description"`
7. Push commits and tag: `git push origin main && git push origin vX.Y.Z`
8. Create GitHub Release (optional) with CHANGELOG content

**Pre-1.0.0 Note:** During `0.x.x` phase, breaking changes can be in MINOR versions. Move to `1.0.0` when API is stable.

## Documentation Standards

### Required Files

- ✅ **DESIGN.md** - Project design and architecture
- ✅ **PLAN.md** - Implementation tasks and progress
- ✅ **CHANGELOG.md** - Change history (Keep a Changelog format)
- ✅ **README.md** - Usage instructions
- ✅ **AGENTS.md** - This file (project-specific best practices)
- ✅ **.cursorrules** - AI agent instructions

### Documentation Best Practices

- **Keep documentation current** with code changes
- **Document security considerations** clearly
- **Include examples** for common use cases
- **Reference external documentation** where appropriate
- **Update CHANGELOG.md** for all notable changes

## Testing Standards

### Current State

- ⚠️ **No automated tests** currently implemented
- ✅ **Manual validation** via `terraform validate` and `terraform fmt`
- 📋 **Planned:** Add Terraform validation tests (see PLAN.md)

### Best Practices

- Run `terraform validate` before committing
- Run `terraform fmt -check` in CI/CD
- Add validation tests for critical modules
- Test both public and private cluster scenarios

## CI/CD Standards

### Current State

- ⚠️ **No CI/CD pipeline** currently configured
- 📋 **Planned:** Add GitHub Actions workflow (see PLAN.md)

### Best Practices (When Implemented)

- Run `terraform validate` on pull requests
- Run `terraform fmt -check` on pull requests
- Run `terraform plan` to verify changes
- Require approvals for production deployments

## Summary

This project follows MOBB RULES best practices with context-aware application:

- ✅ **Terraform standards** - Proper file organization, variables, outputs, naming
- ✅ **Azure standards** - Naming conventions, tagging, security groups
- ✅ **ARO standards** - Cluster configuration, networking, egress control
- ✅ **Context-aware** - Permissive defaults for examples, documented production hardening
- ✅ **Documentation** - All mandatory files present and current
- ✅ **Design alignment** - Practices support DESIGN.md intent

**Key Principles Applied:**
- Simplicity over complexity
- WET over DRY (appropriate duplication for clarity)
- Context-aware application (example/demo context with production guidance)

**Areas for Future Improvement:**
- Add automated tests
- Add CI/CD pipeline
- Implement security hardening examples
- Expand documentation with more use cases
