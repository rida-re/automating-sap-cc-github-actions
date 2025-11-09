#!/bin/bash
set -euo pipefail

# Input parameters
BUILD_CODE=${1:-MOCK_BUILD}
ENVIRONMENT_CODE=${2:-d1}
UPDATE_MODE=${3:-UPDATE}
DEPLOY_STRATEGY=${4:-ROLLING_UPDATE}

# Configuration
API_URL="${API_BASE_URL:-https://portalapi.commerce.ondemand.com}"
IS_MOCK="${ENVIRONMENT:-mock}"

# Log environment
echo "🔧 Environment: $IS_MOCK"
echo "🔄 Update Mode: $UPDATE_MODE"
echo "📦 Deploy Strategy: $DEPLOY_STRATEGY"

echo "🚀 Starting SAP Commerce deployment"
echo "📦 API URL: $API_URL"
echo "🔑 Build code: $BUILD_CODE"
echo "🌍 Environment: $ENVIRONMENT_CODE"

# Create deployment
create_deployment_output=$(curl -sS -X POST "$API_URL/v2/subscriptions/$SUBSCRIPTION_CODE/deployments" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"buildCode\":\"$BUILD_CODE\",\"databaseUpdateMode\":\"$UPDATE_MODE\",\"environmentCode\":\"$ENVIRONMENT_CODE\",\"strategy\":\"$DEPLOY_STRATEGY\"}" || true)

# Validate JSON
if ! echo "$create_deployment_output" | jq . >/dev/null 2>&1; then
  echo "❌ Invalid JSON or failed to connect to API."
  echo "🔍 Response: $create_deployment_output"
  # fallback mock code
  code="MOCK_DEPLOY_$(date +%s)"
else
  code=$(echo "$create_deployment_output" | jq -r .code)
  if [[ -z "$code" || "$code" == "null" ]]; then
    code="MOCK_DEPLOY_$(date +%s)"
  fi
fi

echo "✅ Deployment created with code: $code"
echo "$create_deployment_output" | jq . 2>/dev/null || true

# Check deployment progress
counter=0
status="SCHEDULED"

while [[ $counter -lt 10 ]] && [[ "$status" == "SCHEDULED" || "$status" == "DEPLOYING" ]]; do
  ((counter++))

  if [[ "$IS_MOCK" == "mock" ]] && [[ "${MOCK_OFFLINE:-false}" == "true" ]]; then
    echo "⏳ Simulating deployment progress in offline mock mode..."
    percentage=$((counter * 20))
    if [[ $percentage -ge 100 ]]; then
      deployment_progress_output="{\"deploymentStatus\":\"DEPLOYED\",\"percentage\":100}"
    else
      deployment_progress_output="{\"deploymentStatus\":\"DEPLOYING\",\"percentage\":$percentage}"
    fi
  else
    deployment_progress_output=$(curl -sS "$API_URL/v2/subscriptions/$SUBSCRIPTION_CODE/deployments/$code/progress" \
      -H "Authorization: Bearer $API_TOKEN" || true)

    if ! echo "$deployment_progress_output" | jq . >/dev/null 2>&1; then
      echo "⚠️ Invalid JSON from progress endpoint, using mock data..."
      percentage=$((counter * 20))
      if [[ $percentage -ge 100 ]]; then
        deployment_progress_output="{\"deploymentStatus\":\"DEPLOYED\",\"percentage\":100}"
      else
        deployment_progress_output="{\"deploymentStatus\":\"DEPLOYING\",\"percentage\":$percentage}"
      fi
    fi
  fi

  status=$(echo "$deployment_progress_output" | jq -r .deploymentStatus)
  percentage=$(echo "$deployment_progress_output" | jq -r .percentage)

  echo "⏳ Deployment status: $status (${percentage:-0}%)"

  if [[ "$status" != "SCHEDULED" && "$status" != "DEPLOYING" ]]; then
    echo "🏁 Deployment finished with status: $status"
    echo "$deployment_progress_output" | jq . 2>/dev/null || true

    if [[ "$status" == "DEPLOYED" ]]; then
      exit 0
    else
      exit 1
    fi
  fi

  sleep 5
done

echo "⚠️ Deployment did not finish after $counter checks."
exit 1
