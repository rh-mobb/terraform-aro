#!/bin/bash

#AZR_CLUSTER="mobb-infra-aro"
#AZR_RESOURCE_GROUP="mobb-infra-aro"

ARO_API=$(az aro show  --name ${AZR_CLUSTER} --resource-group ${AZR_RESOURCE_GROUP} -o tsv --query apiserverProfile.url)

ARO_KUBEPASS=$(az aro list-credentials --name ${AZR_CLUSTER} --resource-group ${AZR_RESOURCE_GROUP} -o tsv --query kubeadminPassword)

echo $ARO_API
echo $ARO_KUBEPASS

oc login ${ARO_API} --username kubeadmin --password ${ARO_KUBEPASS}

oc whoami

until kubectl apply -k https://github.com/RedHatWorkshops/openshift-cicd-demo/bootstrap/overlays/base.cluster/
do
  sleep 5
done

oc patch subscriptions.operators.coreos.com/openshift-gitops-operator -n openshift-operators --type='merge' \
--patch '{ "spec": { "config": { "env": [ { "name": "DISABLE_DEX", "value": "false" } ] } } }'

oc patch argocd/openshift-gitops -n openshift-gitops --type='merge' \
--patch='{ "spec": { "dex": { "openShiftOAuth": true } } }'

oc patch ArgoCD/openshift-gitops -n openshift-gitops --type=merge -p '{"spec":{"rbac":{"defaultPolicy":"role:admin"}}}'

ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}{"\n"}')

while [ `curl -ks -o /dev/null -w "%{http_code}" https://$ARGOCD_ROUTE` != 200 ];do
  echo "waiting for ArgoCD"
  sleep 10
done
  echo "ArgoCD operator"

echo "Add a GitOps Example Application with Kustomize"
oc apply -n openshift-gitops -f https://raw.githubusercontent.com/rh-mobb/gitops-bgd-app/bootstrap/gitops/applications/base/bgd.yaml

echo "Add a GitOps Example Application with Helm"
oc apply -n openshift-gitops -f https://raw.githubusercontent.com/rh-mobb/gitops-bgd-app/bootstrap/gitops/applications/base/pact-broker-helm.yaml
