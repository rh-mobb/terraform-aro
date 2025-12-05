#!/bin/bash
# Destroy ARO cluster with managed identities
# This script ensures proper destroy order: cluster first, then remaining resources
# Usage: destroy-managed-identity.sh [--auto-approve]

set -e

AUTO_APPROVE="-auto-approve"

SUBSCRIPTION_ID=$(az account show --query id --output tsv)

echo "Destroying ARO cluster resources (managed identity)..."
echo "Step 1: Destroying cluster (if exists)..."

if terraform state list 2>/dev/null | grep -q "azurerm_resource_group_template_deployment.cluster_managed_identity"; then
    # Try to destroy with Terraform first
    set +e  # Temporarily disable exit on error to handle the known ARM template cleanup issue
    TERRAFORM_OUTPUT=$(terraform destroy -target=azurerm_resource_group_template_deployment.cluster_managed_identity \
        -var "subscription_id=${SUBSCRIPTION_ID}" ${AUTO_APPROVE} 2>&1)
    TERRAFORM_EXIT=$?
    set -e  # Re-enable exit on error

    # Check if it's the known OutputResources error
    if [ ${TERRAFORM_EXIT} -ne 0 ] && (echo "${TERRAFORM_OUTPUT}" | grep -q "OutputResources.*was nil\|insufficient data to clean up"); then
        echo ""
        echo "⚠ Warning: Terraform cannot clean up ARM template deployment (known limitation)"
        echo "  Falling back to Azure CLI deletion..."

        # Get deployment details from state (more reliable than outputs)
        STATE_OUTPUT=$(terraform state show 'azurerm_resource_group_template_deployment.cluster_managed_identity[0]' 2>/dev/null || echo "")
        DEPLOYMENT_NAME=$(echo "${STATE_OUTPUT}" | grep -E '^\s+name\s+=' | awk '{print $3}' | tr -d '"' || echo "")
        RESOURCE_GROUP=$(echo "${STATE_OUTPUT}" | grep -E '^\s+resource_group_name\s+=' | awk '{print $3}' | tr -d '"' || echo "")

        if [ -z "${DEPLOYMENT_NAME}" ] || [ -z "${RESOURCE_GROUP}" ]; then
            echo "  ⚠ Error: Could not determine deployment name/resource group from state"
            echo "  Manual cleanup required. Try:"
            echo "    terraform state list | grep cluster_managed_identity"
            echo "    terraform state show <resource-address>"
            exit 1
        fi

        # Extract cluster name from deployment name (format: ${cluster_name}-managed-identity)
        CLUSTER_NAME=$(echo "${DEPLOYMENT_NAME}" | sed 's/-managed-identity$//' || echo "")

        # Check if cluster still exists and delete it first
        if [ -n "${CLUSTER_NAME}" ] && az aro show --name "${CLUSTER_NAME}" --resource-group "${RESOURCE_GROUP}" --output none 2>/dev/null; then
            echo "  Deleting ARO cluster '${CLUSTER_NAME}' using Azure CLI..."
            set +e
            az aro delete \
                --name "${CLUSTER_NAME}" \
                --resource-group "${RESOURCE_GROUP}" \
                --yes \
                --no-wait 2>/dev/null
            set -e
            echo "  Cluster deletion initiated, will wait for completion..."
        else
            echo "  Cluster already deleted or doesn't exist (checking deployment only)"
        fi

        # Delete the deployment using Azure CLI
        echo "  Deleting deployment '${DEPLOYMENT_NAME}' in resource group '${RESOURCE_GROUP}'..."
        set +e
        az deployment group delete \
            --name "${DEPLOYMENT_NAME}" \
            --resource-group "${RESOURCE_GROUP}" \
            --no-wait 2>/dev/null
        DEPLOYMENT_DELETE_EXIT=$?
        set -e

        if [ ${DEPLOYMENT_DELETE_EXIT} -eq 0 ]; then
            echo "  ✓ Deployment deletion initiated"
        else
            echo "  ⚠ Warning: Deployment deletion command failed (may already be deleted)"
        fi

        # Wait a moment for deletion to start
        sleep 5

        # Remove from Terraform state
        echo "  Removing deployment from Terraform state..."
        set +e
        terraform state rm 'azurerm_resource_group_template_deployment.cluster_managed_identity[0]' 2>/dev/null
        STATE_RM_EXIT=$?
        set -e

        if [ ${STATE_RM_EXIT} -eq 0 ]; then
            echo "  ✓ Removed from Terraform state"
        else
            echo "  ⚠ Warning: Could not remove from state (may already be removed)"
        fi
    elif [ ${TERRAFORM_EXIT} -ne 0 ]; then
        echo "⚠ Warning: Cluster destroy had errors, but continuing..."
        echo "${TERRAFORM_OUTPUT}" | tail -20
    fi

    echo ""
    echo "Waiting for cluster to be fully deleted (this may take several minutes)..."

    # Get cluster name and resource group (try from outputs first, fallback to state if needed)
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")

    # If outputs are empty, try to get from state
    if [ -z "${CLUSTER_NAME}" ] || [ -z "${RESOURCE_GROUP}" ]; then
        STATE_OUTPUT=$(terraform state show 'azurerm_resource_group_template_deployment.cluster_managed_identity[0]' 2>/dev/null || echo "")
        if [ -n "${STATE_OUTPUT}" ]; then
            DEPLOYMENT_NAME=$(echo "${STATE_OUTPUT}" | grep -E '^\s+name\s+=' | awk '{print $3}' | tr -d '"' || echo "")
            RESOURCE_GROUP=$(echo "${STATE_OUTPUT}" | grep -E '^\s+resource_group_name\s+=' | awk '{print $3}' | tr -d '"' || echo "")
            CLUSTER_NAME=$(echo "${DEPLOYMENT_NAME}" | sed 's/-managed-identity$//' || echo "")
        fi
    fi

    if [ -n "${CLUSTER_NAME}" ] && [ -n "${RESOURCE_GROUP}" ]; then
        MAX_WAIT=600
        WAITED=0
        while [ ${WAITED} -lt ${MAX_WAIT} ]; do
            if ! az aro show --name "${CLUSTER_NAME}" --resource-group "${RESOURCE_GROUP}" --output none 2>/dev/null; then
                echo "✓ Cluster confirmed deleted"
                break
            fi
            echo "  Waiting for cluster deletion... (${WAITED}/${MAX_WAIT} seconds)"
            sleep 10
            WAITED=$((WAITED + 10))
        done

        if [ ${WAITED} -ge ${MAX_WAIT} ]; then
            echo "⚠ Warning: Cluster deletion check timed out after ${MAX_WAIT} seconds"
            echo "  Proceeding with caution - cluster may still be deleting"
        fi
    else
        echo "⚠ Warning: Could not determine cluster name/resource group from outputs"
        echo "  Waiting 60 seconds as safety buffer..."
        sleep 60
    fi
else
    echo "No managed identity cluster found in state, skipping cluster destroy"
fi

echo "Step 2: Destroying all remaining resources (managed identities, networks, etc.)..."
terraform destroy -var "subscription_id=${SUBSCRIPTION_ID}" ${AUTO_APPROVE}
