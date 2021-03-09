#!/bin/bash

if ! gcloud auth print-access-token &> /dev/null
then
  gcloud auth login
fi

# unset KUBECONFIG because otherwise config would be generated in local ``kube.config``
# file:
unset KUBECONFIG

gcloud container clusters get-credentials production --zone europe-west3-a --project zeitonline-main
gcloud container clusters get-credentials staging --zone europe-west3-a --project zeitonline-main
gcloud container clusters get-credentials devel --zone europe-west3-a --project zeitonline-main
gcloud container clusters get-credentials zon-misc-prod-1 --zone europe-west3-a --project zeitonline-gke-misc-prod

# Fetch GCP Application Default Credentials like Terraform uses 'em
if ! gcloud auth application-default print-access-token &> /dev/null
then
  gcloud auth application-default login --billing-project=zeitonline-210413
fi
