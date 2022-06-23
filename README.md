# Using Terraform to build an ARO cluster

Azure Red Hat OpenShift (ARO) is a fully-managed turnkey application platform.

## Create the AWS Virtual Private Cloud (VPCs), Pub/Private Subnets and TGW

### Setup

Using the code in the repo will require having the following tools installed:

- The Terraform CLI
- The OC CLI

### Create the ARO cluster and required infrastructure

1. Modify the `variable.tf` var file, or modify the following command to customize your cluster.

   ```
   terraform init
   terraform plan -var "cluster_name=my-tf-cluster" -out aro.plan
   terraform apply aro.plan
   ```

### Test Connectivity

1. Get the ARO cluster's console URL.

   ```
   az aro show \
     --name $AZR_CLUSTER \
     --resource-group $AZR_RESOURCE_GROUP \
     -o tsv --query consoleProfile
   ```

1. Get the ARO cluster's credentials.

   ```
   az aro list-credentials \
    --name $AZR_CLUSTER \
    --resource-group $AZR_RESOURCE_GROUP \
    -o tsv
   ```

1. Log into the cluster using oc login command from the create admin command above. ex.

    ```bash
    oc login https://api.$YOUR_OPENSHIFT_DNS:6443 --username kubeadmin --password xxxxxxxxxx
    ```

1. Check that you can access the Console by opening the console url in your browser.


## Cleanup

1. Delete Cluster and Resources

    ```bash
    terraform destroy -auto-approve "aro.plan"
    ```
