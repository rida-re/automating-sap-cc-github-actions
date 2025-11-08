#!/bin/bash

branch=$1
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")

API_URL="${API_BASE_URL:-https://portalapi.commerce.ondemand.com}"

create_build_output=$(curl -s -X POST "$API_URL/v2/subscriptions/$SUBSCRIPTION_CODE/builds" \
  --header "Authorization: Bearer $API_TOKEN" \
  --data "{\"branch\":\"$1\",\"name\":\"$1-build\"}")

# Vérifie si la requête a réussi
if [ $? -ne 0 ]; then
  echo "$create_build_output" | jq .
  exit 1
fi

code=$(echo "$create_build_output" | jq -r .code)
echo "Successfully created build:"
echo "$create_build_output" | jq .

# Partage du code de build avec le job suivant
echo "build_code=$code" >> "$GITHUB_OUTPUT"

counter=0
status="UNKNOWN"

while [[ $counter -lt 100 ]] && [[ "$status" == "UNKNOWN" || "$status" == "BUILDING" ]]; do
  let counter=counter+1 

  build_progress_output=$(curl -K "./.github/curl-config.txt" \
    --header "Authorization: Bearer $API_TOKEN" \
    "https://portalapi.commerce.ondemand.com/v2/subscriptions/$SUBSCRIPTION_CODE/builds/$code/progress")

  if [ $? -ne 0 ]; then
    echo "$build_progress_output" | jq .
    exit 1
  fi

  status=$(echo "$build_progress_output" | jq -r .buildStatus)
  percentage=$(echo "$build_progress_output" | jq -r .percentage)
  echo "$status $percentage%"

  if [[ "$status" != "UNKNOWN" && "$status" != "BUILDING" ]]; then
    echo "Build has reached end state: $status"
    echo "$build_progress_output" | jq .

    if [[ "$status" == "SUCCESS" ]]; then
      exit 0
    fi

    if [[ "$status" == "FAILURE" ]]; then
      exit 1
    fi
  fi

  sleep 150
done
