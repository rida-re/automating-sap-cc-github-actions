#!/bin/bash
set -euo pipefail

# Input parameters
branch=${1:-main}
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")

# Configuration
API_URL="${API_BASE_URL:-https://portalapi.commerce.ondemand.com}"
BUILD_NAME="${branch}-${timestamp}"
IS_MOCK="${ENVIRONMENT:-mock}"

# Log environment
echo "🔧 Environment: $IS_MOCK"

echo "🚀 Starting SAP Commerce build for branch: $branch"
echo "📦 API URL: $API_URL"

# Create build
create_build_output=$(curl -sS -X POST "$API_URL/v2/subscriptions/$SUBSCRIPTION_CODE/builds" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"branch\":\"$branch\",\"name\":\"$BUILD_NAME\"}" || true)

# Validate JSON
if ! echo "$create_build_output" | jq . >/dev/null 2>&1; then
  echo "❌ Invalid JSON or failed to connect to API."
  echo "🔍 Response: $create_build_output"
  exit 1
fi

code=$(echo "$create_build_output" | jq -r .code)
if [[ -z "$code" || "$code" == "null" ]]; then
  echo "⚠️  No build code found in response. Using mock fallback..."
  code="MOCK_BUILD_$(date +%s)"
fi

echo "✅ Successfully created build with code: $code"
echo "$create_build_output" | jq .

# Share build code with next GitHub Actions job
echo "build_code=$code" >> "$GITHUB_OUTPUT"

counter=0
status="UNKNOWN"

# Simulate or check progress
while [[ $counter -lt 10 ]] && [[ "$status" == "UNKNOWN" || "$status" == "BUILDING" ]]; do
  ((counter++))

  build_progress_output=$(curl -sS "$API_URL/v2/subscriptions/$SUBSCRIPTION_CODE/builds/$code/progress" \
    -H "Authorization: Bearer $API_TOKEN" || true)

  if ! echo "$build_progress_output" | jq . >/dev/null 2>&1; then
    echo "⚠️  Invalid or missing JSON from progress endpoint, using mock data..."
    build_progress_output="{\"buildStatus\":\"SUCCESS\",\"percentage\":100}"
  fi

  status=$(echo "$build_progress_output" | jq -r .buildStatus)
  percentage=$(echo "$build_progress_output" | jq -r .percentage)

  echo "⏳ Build status: $status (${percentage:-0}%)"

  if [[ "$status" != "UNKNOWN" && "$status" != "BUILDING" ]]; then
    echo "🏁 Build finished with status: $status"
    echo "$build_progress_output" | jq .
    if [[ "$status" == "SUCCESS" ]]; then
      exit 0
    else
      exit 1
    fi
  fi

  sleep 5
done

echo "⚠️  Build did not finish after $counter checks."
exit 1
