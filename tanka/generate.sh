#!/bin/bash

set -ex

PROJECT="${PROJECT:-hipstershop1}"
NAMESPACE="${NAMESPACE:-hipstershop1}"

for scenario in $(ls environments) 
do
  echo "procerssing $scenario"
  tk show environments/${scenario} --dangerous-allow-redirect \
  -e externalURLs='{}' \
  -e externalApps='[]' \
  --extVar project=${PROJECT} \
  --extVar namespace=${NAMESPACE} > ../hipstershop-${scenario}.yaml
done
