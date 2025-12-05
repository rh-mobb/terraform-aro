AZR_LOCATION ?= eastus
ARO_CLUSTER_NAME ?= example
ARO_VNET_RESOURCE_GROUP ?= $(ARO_CLUSTER_NAME)-vnet-rg
ARO_VNET_CIDR ?= 10.0.0.0/22
ARO_VNET_CONTROL_CIDR ?= 10.0.0.0/23
ARO_VNET_WORKER_CIDR ?= 10.0.2.0/23
ARO_PULL_SECRET ?= ~/.azure/aro-pull-secret.txt

#
# setup tasks for testing
#
setup-test:
	az group create \
		--name $(ARO_VNET_RESOURCE_GROUP) \
		--location $(AZR_LOCATION)

	az network vnet create \
		--address-prefixes $(ARO_VNET_CIDR) \
		--name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
		--resource-group $(ARO_VNET_RESOURCE_GROUP)

	az network vnet subnet create \
		--resource-group $(ARO_VNET_RESOURCE_GROUP) \
		--vnet-name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
		--name "$(ARO_CLUSTER_NAME)-aro-control-subnet-$(AZR_LOCATION)" \
		--address-prefixes "$(ARO_VNET_CONTROL_CIDR)"

	az network vnet subnet create \
		--resource-group $(ARO_VNET_RESOURCE_GROUP) \
		--vnet-name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
		--name "$(ARO_CLUSTER_NAME)-aro-worker-subnet-$(AZR_LOCATION)" \
		--address-prefixes "$(ARO_VNET_WORKER_CIDR)"

	az network vnet subnet update \
		--name "$(ARO_CLUSTER_NAME)-aro-control-subnet-$(AZR_LOCATION)" \
		--resource-group $(ARO_VNET_RESOURCE_GROUP) \
		--vnet-name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
		--disable-private-link-service-network-policies true

	NSG=$$(az network nsg create --resource-group $(ARO_VNET_RESOURCE_GROUP) --name $(ARO_CLUSTER_NAME)-nsg -o tsv --query NewNSG.id)

# NOTE: add this to the above make target when pre-configured NSG is available in the TF provider.  until then we can skip testing.
# az network vnet subnet update \
# 	--name "$(ARO_CLUSTER_NAME)-aro-control-subnet-$(AZR_LOCATION)" \
# 	--resource-group $(ARO_VNET_RESOURCE_GROUP) \
# 	--vnet-name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
# 	--nsg $${NSG}

# az network vnet subnet update \
# 	--name "$(ARO_CLUSTER_NAME)-aro-worker-subnet-$(AZR_LOCATION)" \
# 	--resource-group $(ARO_VNET_RESOURCE_GROUP) \
# 	--vnet-name "$(ARO_CLUSTER_NAME)-aro-vnet-$(AZR_LOCATION)" \
# 	--nsg $${NSG}

setup-cluster:
	az aro create \
		--resource-group $AZR_RESOURCE_GROUP \
		--name $AZR_CLUSTER \
		--vnet "$AZR_CLUSTER-aro-vnet-$AZR_RESOURCE_LOCATION" \
		--master-subnet "$AZR_CLUSTER-aro-control-subnet-$AZR_RESOURCE_LOCATION" \
		--worker-subnet "$AZR_CLUSTER-aro-machine-subnet-$AZR_RESOURCE_LOCATION" \
		--pull-secret @$AZR_PULL_SECRET

#
# teardown tasks when done testing
#
teardown-test:
	az group delete --name $(ARO_VNET_RESOURCE_GROUP) --yes
