#!/bin/bash

set -ex

if [ ! -d "environments" ]; then
  echo "you need to be inside the tanka directory to run this script"
  exit 1
fi

PROJECT="${PROJECT:-hipstershop1}"
NAMESPACE="${NAMESPACE:-hipstershop1}"

for scenario in $(ls environments) 
do
  echo "procerssing $scenario"
  tk show environments/${scenario} --dangerous-allow-redirect \
  -e manualConfig="{project: \"${PROJECT}\", namespace: \"${NAMESPACE}\"}" \
  -e selectedApps='[]' > ../release/hipstershop-${scenario}.yaml
done
