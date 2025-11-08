[bash]#!/bin/bash

create_deployment_output=$(curl -K "./scripts/curl-config.txt" \
  -X POST "https://portalapi.commerce.ondemand.com/v2/subscriptions/$SUBSCRIPTION_CODE/deployments" \
  --header "Authorization: Bearer $API_TOKEN" \
  --data "{\"buildCode\":\"$1\",\"databaseUpdateMode\":\"UPDATE\", \"environmentCode\": \"$2\", \"strategy\": \"ROLLING_UPDATE\"}")

# Check if the command succeeded
if [ $? -ne 0 ]; then
  echo "$create_deployment_output" | jq .
  exit 1
fi

code=$(echo $create_deployment_output | jq -r .code)
echo "Successfully created deployment:"
echo $create_deployment_output | jq .

counter=0
status=SCHEDULED

while [[ $counter -lt 100 ]] && [[ "$status" == "SCHEDULED" || "$status" == "DEPLOYING" ]]; do
  let counter=counter+1 

  deployment_progress_output=$(curl -K "./scripts/curl-config.txt" \
    --header "Authorization: Bearer $API_TOKEN" \
    "https://portalapi.commerce.ondemand.com/v2/subscriptions/$SUBSCRIPTION_CODE/deployments/$code/progress")
    
  # Check if the command succeeded
  if [ $? -ne 0 ]; then
    echo "$deployment_progress_output" | jq .
    exit 1
  fi

  status=$(echo $deployment_progress_output | jq -r .deploymentStatus)
  percentage=$(echo $deployment_progress_output | jq -r .percentage)
  echo "$status $percentage%"

  if [[ "$status" != "SCHEDULED" && "$status" != "DEPLOYING" ]]; then
    echo "build has reached end state: $status"
    echo $deployment_progress_output | jq .

    if [[ "$status" == "DEPLOYED" ]]; then
      exit 0
    fi

    if [[ "$status" == "FAIL" ]]; then
      exit 1
    fi
  fi

  sleep 150

done[/bash]
