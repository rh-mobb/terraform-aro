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
	terraform plan -out aro.plan 		                       \
		-var "subscription_id=$(shell az account show --query id --output tsv)"     \
		-var "cluster_name=aro-$(shell whoami)" \
		-var "aro_version=$(shell az aro get-versions -l eastus --query '[-1]' | sed 's/"//g')"

	terraform apply aro.plan

.PHONY: create-private
create-private: init
	terraform plan -out aro.plan 		                       \
		-var "cluster_name=aro-$(shell whoami)"              \
		-var "restrict_egress_traffic=true"		               \
		-var "api_server_profile=Private"                    \
		-var "ingress_profile=Private"                       \
		-var "outbound_type=UserDefinedRouting"              \
		-var "subscription_id=$(shell az account show --query id --output tsv)"     \
		-var "aro_version=$(shell az aro get-versions -l eastus --query '[-1]' | sed 's/"//g')" \
		-var "acr_private=false"

	terraform apply aro.plan

.PHONY: create-private-noegress
create-private-noegress: init
	terraform plan -out aro.plan 		                       \
		-var "cluster_name=aro-$(shell whoami)"              \
		-var "restrict_egress_traffic=false"		             \
		-var "api_server_profile=Private"                    \
		-var "ingress_profile=Private"                       \
		-var "aro_version=$(shell az aro get-versions -l eastus --query '[-1]' | sed 's/"//g')" \
		-var "subscription_id=$(shell az account show --query id --output tsv)"

	terraform apply aro.plan

.PHONY: destroy
destroy:
	terraform destroy -var "subscription_id=$(shell az account show --query id --output tsv)"

.PHONY: destroy.force
destroy.force:
	terraform destroy -auto-approve -var "subscription_id=$(shell az account show --query id --output tsv)"

.PHONY: delete
delete: destroy

.PHONY: clean
clean:
	rm -rf terraform.tfstate*
	rm -rf .terraform*
