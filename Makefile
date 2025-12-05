.DEFAULT_GOAL := help

.PHONY: help
help:
	less ./README.md

.PHONY: tfvars
tfvars:
	cp ./terraform.tfvars.example terraform.tfvars

.PHONY: init
init:
	terraform init -upgrade

.PHONY: create
create: init
	# NOTE: aro_version is optional - latest version will be auto-detected if not provided
	terraform plan -out aro.plan \
		-var "subscription_id=$(shell az account show --query id --output tsv)" \
		-var "cluster_name=aro-$(shell whoami)"

	terraform apply aro.plan

.PHONY: create-private
create-private: init
	# NOTE: aro_version is optional - latest version will be auto-detected if not provided
	terraform plan -out aro.plan \
		-var "cluster_name=aro-$(shell whoami)" \
		-var "restrict_egress_traffic=true" \
		-var "api_server_profile=Private" \
		-var "ingress_profile=Private" \
		-var "outbound_type=UserDefinedRouting" \
		-var "subscription_id=$(shell az account show --query id --output tsv)" \
		-var "acr_private=false"

	terraform apply aro.plan

.PHONY: create-private-noegress
create-private-noegress: init
	# NOTE: aro_version is optional - latest version will be auto-detected if not provided
	terraform plan -out aro.plan \
		-var "cluster_name=aro-$(shell whoami)" \
		-var "restrict_egress_traffic=false" \
		-var "api_server_profile=Private" \
		-var "ingress_profile=Private" \
		-var "subscription_id=$(shell az account show --query id --output tsv)"

	terraform apply aro.plan

.PHONY: create-managed-identity
create-managed-identity: init
	# NOTE: Deploys ARO cluster with managed identities (preview feature)
	# NOTE: aro_version is optional - latest version will be auto-detected if not provided
	terraform plan -out aro.plan \
		-var "subscription_id=$(shell az account show --query id --output tsv)" \
		-var "cluster_name=aro-$(shell whoami)" \
		-var "enable_managed_identities=true"

	terraform apply aro.plan

.PHONY: create-private-managed-identity
create-private-managed-identity: init
	# NOTE: Deploys private ARO cluster with managed identities (preview feature)
	# NOTE: aro_version is optional - latest version will be auto-detected if not provided
	terraform plan -out aro.plan \
		-var "cluster_name=aro-$(shell whoami)" \
		-var "enable_managed_identities=true" \
		-var "restrict_egress_traffic=true" \
		-var "api_server_profile=Private" \
		-var "ingress_profile=Private" \
		-var "outbound_type=UserDefinedRouting" \
		-var "subscription_id=$(shell az account show --query id --output tsv)" \
		-var "acr_private=false"

	terraform apply aro.plan

.PHONY: delete
delete: destroy

.PHONY: destroy
destroy:
	# NOTE: Check if this is a managed identity cluster - if so, use destroy-managed-identity instead
	@bash -c '\
	set -e; \
	if terraform state list 2>/dev/null | grep -q "azurerm_resource_group_template_deployment.cluster_managed_identity"; then \
		echo "❌ Error: This is a managed identity cluster."; \
		echo ""; \
		echo "Managed identity clusters require special destroy handling."; \
		echo "Please use: make destroy-managed-identity"; \
		echo ""; \
		exit 1; \
	fi; \
	echo "Destroying ARO cluster resources (service principal)..."; \
	terraform destroy -auto-approve -var "subscription_id=$$(az account show --query id --output tsv)"'

.PHONY: destroy-managed-identity
destroy-managed-identity:
	# NOTE: Destroy order is critical for managed identity clusters - cluster must be deleted BEFORE modules
	#       ARM template deployments require explicit wait/verification to prevent network resource destruction conflicts
	@./scripts/destroy-managed-identity.sh



.PHONY: clean
clean:
	rm -rf terraform.tfstate*
	rm -rf .terraform*

.PHONY: show_credentials
show_credentials:
	@bash -c '\
	set -e; \
	echo "Retrieving ARO cluster credentials..."; \
	CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null) || { echo "Error: Could not get cluster_name from terraform output. Make sure terraform has been applied."; exit 1; }; \
	RESOURCE_GROUP=$$(terraform output -raw resource_group_name 2>/dev/null) || { echo "Error: Could not get resource_group_name from terraform output. Make sure terraform has been applied."; exit 1; }; \
	API_URL=$$(terraform output -raw api_url 2>/dev/null) || { echo "Error: Could not get api_url from terraform output. Make sure terraform has been applied."; exit 1; }; \
	CONSOLE_URL=$$(terraform output -raw console_url 2>/dev/null) || { echo "Error: Could not get console_url from terraform output. Make sure terraform has been applied."; exit 1; }; \
	echo "Cluster: $$CLUSTER_NAME"; \
	echo "Resource Group: $$RESOURCE_GROUP"; \
	echo "API URL: $$API_URL"; \
	echo "Console URL: $$CONSOLE_URL"; \
	echo ""; \
	CREDS_JSON=$$(az aro list-credentials --name $$CLUSTER_NAME --resource-group $$RESOURCE_GROUP --output json 2>/dev/null) || { echo "Error: Could not get cluster credentials. Make sure you'\''re logged into Azure CLI."; exit 1; }; \
	if command -v jq >/dev/null 2>&1; then \
		KUBEADMIN_USERNAME=$$(echo $$CREDS_JSON | jq -r ".kubeadminUsername" 2>/dev/null); \
		KUBEADMIN_PASSWORD=$$(echo $$CREDS_JSON | jq -r ".kubeadminPassword" 2>/dev/null); \
	else \
		KUBEADMIN_USERNAME=$$(echo $$CREDS_JSON | grep -o "\"kubeadminUsername\": \"[^\"]*\"" | cut -d"\"" -f4); \
		KUBEADMIN_PASSWORD=$$(echo $$CREDS_JSON | grep -o "\"kubeadminPassword\": \"[^\"]*\"" | cut -d"\"" -f4); \
	fi; \
	if [ -z "$$KUBEADMIN_USERNAME" ] || [ -z "$$KUBEADMIN_PASSWORD" ]; then \
		echo "Error: Could not extract credentials from az aro list-credentials output"; \
		exit 1; \
	fi; \
	echo "Username: $$KUBEADMIN_USERNAME"; \
	echo "Password: $$KUBEADMIN_PASSWORD"; \
	echo ""; \
	echo "To login, run: oc login $$API_URL --username=$$KUBEADMIN_USERNAME --password=$$KUBEADMIN_PASSWORD --insecure-skip-tls-verify=true"; \
	echo "Or use: make login"'

.PHONY: login
login:
	@bash -c '\
	set -e; \
	echo "Logging into ARO cluster..."; \
	CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null) || { echo "Error: Could not get cluster_name from terraform output. Make sure terraform has been applied."; exit 1; }; \
	RESOURCE_GROUP=$$(terraform output -raw resource_group_name 2>/dev/null) || { echo "Error: Could not get resource_group_name from terraform output. Make sure terraform has been applied."; exit 1; }; \
	API_URL=$$(terraform output -raw api_url 2>/dev/null) || { echo "Error: Could not get api_url from terraform output. Make sure terraform has been applied."; exit 1; }; \
	echo "Cluster: $$CLUSTER_NAME"; \
	echo "Resource Group: $$RESOURCE_GROUP"; \
	echo "API URL: $$API_URL"; \
	CREDS_JSON=$$(az aro list-credentials --name $$CLUSTER_NAME --resource-group $$RESOURCE_GROUP --output json 2>/dev/null) || { echo "Error: Could not get cluster credentials. Make sure you'\''re logged into Azure CLI."; exit 1; }; \
	if command -v jq >/dev/null 2>&1; then \
		KUBEADMIN_USERNAME=$$(echo $$CREDS_JSON | jq -r ".kubeadminUsername" 2>/dev/null); \
		KUBEADMIN_PASSWORD=$$(echo $$CREDS_JSON | jq -r ".kubeadminPassword" 2>/dev/null); \
	else \
		KUBEADMIN_USERNAME=$$(echo $$CREDS_JSON | grep -o "\"kubeadminUsername\": \"[^\"]*\"" | cut -d"\"" -f4); \
		KUBEADMIN_PASSWORD=$$(echo $$CREDS_JSON | grep -o "\"kubeadminPassword\": \"[^\"]*\"" | cut -d"\"" -f4); \
	fi; \
	if [ -z "$$KUBEADMIN_USERNAME" ] || [ -z "$$KUBEADMIN_PASSWORD" ]; then \
		echo "Error: Could not extract credentials from az aro list-credentials output"; \
		exit 1; \
	fi; \
	echo "Logging in as kubeadmin..."; \
	oc login $$API_URL --username=$$KUBEADMIN_USERNAME --password=$$KUBEADMIN_PASSWORD --insecure-skip-tls-verify=true || { echo "Error: oc login failed. Make sure '\''oc'\'' CLI is installed."; exit 1; }; \
	echo "Successfully logged into ARO cluster!"'

# MOBB RULES Standard Targets

.PHONY: validate
validate: init
	terraform validate

.PHONY: fmt
fmt:
	terraform fmt -check -recursive

.PHONY: fmt-fix
fmt-fix:
	terraform fmt -recursive

.PHONY: check
check: validate fmt

.PHONY: lint
lint: check
	@echo "Linting: Running terraform validate and fmt checks"
	@echo "Note: Additional linting tools can be added here"

.PHONY: test
test: init
	@echo "Running full test suite..."
	@echo "Running Terraform validate..."
	@terraform validate || { echo "ERROR: Terraform validate failed" >&2; exit 1; }
	@echo "Running Terraform fmt -check..."
	@terraform fmt -check -recursive || { echo "ERROR: Terraform fmt -check failed. Run 'make fmt-fix' to fix." >&2; exit 1; }
	@if command -v tflint >/dev/null 2>&1; then \
		echo "Running tflint..."; \
		tflint --init || true; \
		tflint || { echo "ERROR: tflint failed" >&2; exit 1; }; \
	else \
		echo "⚠ tflint not found (optional - install with: brew install tflint)"; \
	fi
	@if command -v checkov >/dev/null 2>&1; then \
		CHECKOV_VERSION=$$(checkov --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"); \
		EXPECTED_VERSION="3.2.495"; \
		if [ "$$CHECKOV_VERSION" != "$$EXPECTED_VERSION" ] && [ "$$CHECKOV_VERSION" != "unknown" ]; then \
			echo "⚠ Warning: checkov version $$CHECKOV_VERSION detected, but CI uses $$EXPECTED_VERSION"; \
			echo "  Install with: pip install checkov==$$EXPECTED_VERSION"; \
		fi; \
		echo "Running checkov security scan..."; \
		checkov -d . --framework terraform --quiet || { echo "ERROR: checkov security scan failed" >&2; exit 1; }; \
	else \
		echo "⚠ checkov not found (optional - install with: pip install checkov==3.2.495)"; \
	fi
	@echo "Running Terraform plan (dry-run)..."
	@SUBSCRIPTION_ID=$$(az account show --query id --output tsv 2>/dev/null || echo ""); \
	if [ -z "$$SUBSCRIPTION_ID" ]; then \
		echo "⚠ Warning: Azure CLI not logged in, skipping terraform plan"; \
		echo "  Run 'az login' and 'az account set --subscription <subscription-id>' to enable plan test"; \
	else \
		terraform plan -out=test.plan -var "subscription_id=$$SUBSCRIPTION_ID" -var "cluster_name=test-cluster" -var "domain=test.example.com" -lock=false || { echo "ERROR: Terraform plan failed" >&2; rm -f test.plan; exit 1; }; \
		rm -f test.plan; \
	fi
	@echo ""
	@echo "✓ All tests passed!"

.PHONY: pr
pr: init
	@echo "Running pre-commit checks..."
	@echo "Running Terraform validate..."
	@terraform validate || { echo "ERROR: Terraform validate failed" >&2; exit 1; }
	@echo "Running Terraform fmt -check..."
	@terraform fmt -check -recursive || { echo "ERROR: Terraform fmt -check failed. Run 'make fmt-fix' to fix." >&2; exit 1; }
	@if command -v tflint >/dev/null 2>&1; then \
		echo "Running tflint..."; \
		tflint --init || true; \
		tflint || { echo "ERROR: tflint failed" >&2; exit 1; }; \
	else \
		echo "⚠ tflint not found (optional - install with: brew install tflint)"; \
	fi
	@if command -v checkov >/dev/null 2>&1; then \
		CHECKOV_VERSION=$$(checkov --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"); \
		EXPECTED_VERSION="3.2.495"; \
		if [ "$$CHECKOV_VERSION" != "$$EXPECTED_VERSION" ] && [ "$$CHECKOV_VERSION" != "unknown" ]; then \
			echo "⚠ Warning: checkov version $$CHECKOV_VERSION detected, but CI uses $$EXPECTED_VERSION"; \
			echo "  Install with: pip install checkov==$$EXPECTED_VERSION"; \
		fi; \
		echo "Running checkov security scan..."; \
		checkov -d . --framework terraform --quiet || { echo "ERROR: checkov security scan failed" >&2; exit 1; }; \
	else \
		echo "⚠ checkov not found (optional - install with: pip install checkov==3.2.495)"; \
	fi
	@echo ""
	@echo "✓ All pre-commit checks passed! (plan skipped - use 'make test' for full test suite)"
