# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-01

### Added
- `make test` target - Full test suite including terraform validate, fmt, tflint, checkov, and terraform plan
- `make pr` target - Pre-commit checks (validate, fmt, tflint, checkov) without terraform plan
- `make login` target - Automated login to ARO cluster using terraform outputs and Azure CLI credentials
- GitHub Actions workflow (`.github/workflows/pr.yml`) - Automated PR checks with PR comments
  - Runs `make pr` on pull requests and pushes to main
  - Posts PR comments with check results
  - Includes Terraform, tflint, and checkov setup
  - Caches Terraform providers for faster runs
- Terraform outputs: `cluster_name` and `resource_group_name` for easier cluster management
- Checkov inline suppressions with justifications:
  - CKV_TF_1: Module uses semantic version tags for stability
  - CKV_AZURE_119: Jumphost requires public IP for private cluster access
  - CKV2_AZURE_31: Subnets use NSG via associations or private endpoints
- Terraform `required_version` constraint: `>= 1.12`
- Provider version constraints: Added `random` (~>3.0) and `time` (~>0.9) to required_providers

### Changed
- **BREAKING:** Reorganized Terraform files with numeric prefixes per MOBB RULES
  - `terraform.tf` → `00-terraform.tf`
  - `variables.tf` → `01-variables.tf`
  - New: `02-locals.tf` - Consolidated all local values
  - `network.tf` → `10-network.tf`
  - `egress.tf` → `11-egress.tf`
  - `iam.tf` → `20-iam.tf`
  - `jumphost.tf` → `30-jumphost.tf`
  - `acr.tf` → `40-acr.tf`
  - `cluster.tf` → `50-cluster.tf`
  - New: `90-outputs.tf` - Consolidated all outputs
  - Note: Terraform automatically reads all `.tf` files, so functionality unchanged
- **BREAKING:** Standardized resource naming - converted hyphens to underscores
  - `azurerm_subnet.jumphost-subnet` → `azurerm_subnet.jumphost_subnet`
  - `azurerm_public_ip.jumphost-pip` → `azurerm_public_ip.jumphost_pip`
  - `azurerm_network_interface.jumphost-nic` → `azurerm_network_interface.jumphost_nic`
  - `azurerm_network_security_group.jumphost-nsg` → `azurerm_network_security_group.jumphost_nsg`
  - `azurerm_linux_virtual_machine.jumphost-vm` → `azurerm_linux_virtual_machine.jumphost_vm`
  - `azurerm_network_interface_security_group_association.association` → `azurerm_network_interface_security_group_association.jumphost_association`
- Enhanced all variable descriptions with more detail, usage examples, and constraints
- Enhanced TODO comments with context, rationale, and references to DESIGN.md
- **BREAKING:** `aro_version` variable now defaults to `null` instead of `"4.16.30"`
  - If `aro_version` is not provided, the latest available version for the region is automatically detected
  - To specify a version explicitly, set `aro_version = "4.16.30"` (or desired version)
  - Detection uses: `az aro get-versions -l <location>` and selects the latest version

### Added
- Gap analysis comparing existing codebase to MOBB RULES standards
- `02-locals.tf` - Consolidated all local values from multiple files
- `03-data.tf` - Data sources including automatic ARO version detection
- `90-outputs.tf` - Consolidated all outputs from multiple files
- Descriptions added to all 5 outputs (`console_url`, `api_url`, `api_server_ip`, `ingress_ip`, `public_ip`)
- Enhanced variable descriptions with detailed explanations, usage examples, and constraints
- Enhanced TODO comments with context, rationale, and references to DESIGN.md
- Automatic ARO version detection - `aro_version` variable now defaults to `null` and automatically detects latest available version if not provided
- `external` provider added for shell command execution
- DESIGN.md - Project design document documenting architecture, constraints, and design decisions
  - Documents project intent, high-level architecture, design decisions, constraints, and non-goals
  - Includes context-aware security approach documentation
  - References external documentation and future considerations
- PLAN.md - Implementation plan tracking tasks and progress
  - Updated to reflect MOBB RULES adoption progress
- CHANGELOG.md - This file, tracking all notable changes
- AGENTS.md - Project-specific best practices compiled from MOBB RULES
  - Compiles Terraform, Azure, and ARO best practices
  - Documents existing patterns and deviations
  - Includes context-aware application guidelines
  - Documents security approach for example/demo context
- .cursorrules - AI agent instructions referencing AGENTS.md
  - Provides guidelines for AI coding agents working on this project
  - References DESIGN.md, AGENTS.md, and PLAN.md
- Makefile targets: `validate`, `fmt`, `fmt-fix`, `check`, `lint` - Standard MOBB RULES targets for Terraform validation and formatting
  - `validate` - Run terraform validate
  - `fmt` - Check formatting (non-destructive)
  - `fmt-fix` - Fix formatting automatically
  - `check` - Run both validate and fmt checks
  - `lint` - Run linting checks (currently wraps check)
- `make test` - Full test suite with terraform plan (requires Azure CLI login)
- `make pr` - Pre-commit checks without terraform plan (no Azure credentials needed)
- `make login` - Automated ARO cluster login using terraform outputs
- `ManagedBy = "Terraform"` tag to default tags variable

### Changed
- Makefile - Added standard MOBB RULES targets for validation and formatting
- **BREAKING:** Standardized Terraform resource identifiers to use underscores consistently
  - `azurerm_subnet.jumphost-subnet` → `azurerm_subnet.jumphost_subnet`
  - `azurerm_public_ip.jumphost-pip` → `azurerm_public_ip.jumphost_pip`
  - `azurerm_network_interface.jumphost-nic` → `azurerm_network_interface.jumphost_nic`
  - `azurerm_network_security_group.jumphost-nsg` → `azurerm_network_security_group.jumphost_nsg`
  - `azurerm_linux_virtual_machine.jumphost-vm` → `azurerm_linux_virtual_machine.jumphost_vm`
  - `azurerm_network_interface_security_group_association.association` → `azurerm_network_interface_security_group_association.jumphost_association`
- All outputs - Added descriptions per MOBB RULES best practices
- All variables - Improved descriptions for clarity and consistency
- Variables - Added `nullable` attribute to optional variables (`resource_group_name`, `pull_secret_path`, `domain`)
- Variables - Standardized description format (capitalized CIDR, clearer explanations)
- Variables - Fixed typo in `aro_private_endpoint_cidr_block` description
- Variables - Improved validation error messages (fixed "Must be not be empty" → "Must not be empty")

## [0.1.0] - 2024-12-01

### Added
- Initial Terraform codebase for ARO cluster deployment
- Support for public ARO clusters
- Support for private ARO clusters
- Conditional Azure Firewall for egress traffic restriction
- Conditional jumphost VM for private cluster access
- Conditional Azure Container Registry (ACR) with private endpoint
- Service principal management via `terraform-aro-permissions` module
- Basic Makefile with targets: `help`, `tfvars`, `init`, `create`, `create-private`, `create-private-noegress`, `destroy`, `destroy-force`, `delete`, `clean`
- README.md with usage instructions
- variables.tf with comprehensive variable definitions
- terraform.tfvars.example for variable reference

### Notes
- This changelog entry documents the initial state of the project before MOBB RULES adoption
- Project supports both public and private ARO cluster deployments
- Security defaults are permissive for example/demo use cases
- Production deployments require security hardening (documented in DESIGN.md)

[Unreleased]: https://github.com/rh-mobb/terraform-aro/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rh-mobb/terraform-aro/releases/tag/v1.0.0
[0.1.0]: https://github.com/rh-mobb/terraform-aro/releases/tag/v0.1.0
