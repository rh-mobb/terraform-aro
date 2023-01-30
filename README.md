# Using Terraform to build an ARO cluster

Azure Red Hat OpenShift (ARO) is a fully-managed turnkey application platform.

Supports Public ARO clusters and Private ARO clusters.

## Setup

Using the code in the repo will require having the following tools installed:

- The Terraform CLI
- The OC CLI

## Create the ARO cluster and required infrastructure

### Public ARO cluster

1. Modify the `variable.tf` var file, or modify the following command to customize your cluster.

   ```bash
   terraform init
   terraform plan -var "cluster_name=my-tf-cluster" -out aro.plan
   terraform apply aro.plan
   ```

   NOTE: By default the ingress_profile and the api_server_profile is both Public, but can be change using the [TF variables](https://github.com/rh-mobb/terraform-aro/blob/main/variable.tf).

### Private ARO cluster

1. Modify the `variable.tf` var file, or modify the following command to customize your cluster.

   ```bash
   terraform init
   
   terraform plan -var "cluster_name=my-tf-cluster" -var "ingress_profile=Private" -var "api_server_profile=Private" -var "restrict_egress_traffic=true" -out aro.plan

   terraform apply aro.plan
   ```

   NOTE: restrict_egress_traffic=true will secure ARO cluster by routing [Egress traffic through an Azure Firewall](https://learn.microsoft.com/en-us/azure/openshift/howto-restrict-egress).

## Test Connectivity

1. Get the ARO cluster's console URL.

   ```bash
   ARO_URL=$(az aro show -n $AZR_CLUSTER -g $AZR_RESOURCE_GROUP -o json | jq -r '.apiserverProfile.url')
   echo $ARO_URL
   ```

1. Get the ARO cluster's credentials.

   ```bash
   ARO_USERNAME=$(az aro list-credentials -n $AZR_CLUSTER -g $AZR_RESOURCE_GROUP -o json | jq -r '.kubeadminUsername')
   ARO_PASSWORD=$(az aro list-credentials -n $AZR_CLUSTER -g $AZR_RESOURCE_GROUP -o json | jq -r '.kubeadminPassword')
   echo $ARO_PASSWORD
   echo $ARO_USERNAME
   ```

### Public Test Connectivity

1. Log into the cluster using oc login command from the create admin command above. ex.

    ```bash
    oc login $ARO_URL -u $ARO_USERNAME -p $ARO_PASSWORD
    ```

1. Check that you can access the Console by opening the console url in your browser.

### Private Test Connectivity

1. Save the jump host public IP address

    ```bash
   JUMP_IP=$(az vm list-ip-addresses -g $AZR_RESOURCE_GROUP -n $AZR_CLUSTER-jumphost -o tsv \
   --query '[].virtualMachine.network.publicIpAddresses[0].ipAddress')
   echo $JUMP_IP
   ```

1. update /etc/hosts to point the openshift domains to localhost. Use the DNS of your openshift cluster as described in the previous step in place of $YOUR_OPENSHIFT_DNS below

   ```bash
   127.0.0.1 api.$YOUR_OPENSHIFT_DNS
   127.0.0.1 console-openshift-console.apps.$YOUR_OPENSHIFT_DNS
   127.0.0.1 oauth-openshift.apps.$YOUR_OPENSHIFT_DNS
   ```

1. SSH to that instance, tunneling traffic for the appropriate hostnames. Be sure to use your new/existing private key, the OpenShift DNS for $YOUR_OPENSHIFT_DNS and your Jumphost IP

   ```bash
   sudo ssh -L 6443:api.$YOUR_OPENSHIFT_DNS:6443 \
   -L 443:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:443 \
   -L 80:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:80 \
   aro@$JUMP_IP
   ```

1. Log in using oc login

   ```bash
   oc login $ARO_URL -u $ARO_USERNAME -p $ARO_PASSWORD
   ```

## Cleanup

1. Delete Cluster and Resources

    ```bash
    terraform destroy -auto-approve "aro.plan"
    ```
