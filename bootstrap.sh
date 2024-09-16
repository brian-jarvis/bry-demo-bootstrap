#!/bin/bash

LANG=C
SLEEP_SECONDS=30

echo 
echo ""
echo "Installing Google Auth."
kustomize build auth/config | oc apply -f -


echo 
echo ""
echo "Installing user permissions."
kustomize build auth/rbac | oc apply -f -


echo 
echo ""
echo "Installing RHACM Operator."

kustomize build operators/acm | oc apply -f -

echo 
echo ""
echo "Installing RH GitOps Operator."

kustomize build operators/gitops | oc apply -f -

echo "Pause $SLEEP_SECONDS seconds for the creation of the rhacm-operator..."
sleep $SLEEP_SECONDS

echo "Waiting for operator to start"
until oc get deployment multiclusterhub-operator -n open-cluster-management
do
  sleep 10;
done

echo "Installing the MultiClusterHub"

kustomize build operators/acm/hub | oc apply -f -

echo "Waiting for hub to be installed"

until [[ $(oc get multiclusterhub multiclusterhub -n open-cluster-management -o jsonpath='{.status.phase}') == 'Running' ]]
do
  echo "Waiting for hub, current status:"
  oc get multiclusterhub multiclusterhub -n open-cluster-management
  sleep 10
done

echo "Installing policies and initial secrets"

kustomize build policies | oc apply -f -


echo "Check policy compliance with the following command:"
echo "  oc get policy -A"


