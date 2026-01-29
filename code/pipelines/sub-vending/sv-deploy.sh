#!/usr/bin/env bash
#
# sv-deploy.sh
# Location: code/pipelines/sub-vending/
#
# Deploys the subscription vending Bicep template at tenant scope.
# Handles subscription creation with polling, rate limit detection, and error handling.
#
# Usage:
#   bash sv-deploy.sh \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <billingScope> \
#     <existingSubscriptionId> \
#     <projectName> \
#     <managementGroupId> \
#     <workload> \
#     <workloadAlias> \
#     <environment> \
#     <locationCode> \
#     <instanceNumber> \
#     <owner> \
#     <managedBy> \
#     <buildNumber>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed or timed out

set -euo pipefail

# Parameters
TEMPLATE_FILE="${1:-}"
PARAMETERS_FILE="${2:-}"
DEPLOYMENT_LOCATION="${3:-}"
BILLING_SCOPE="${4:-}"
EXISTING_SUB_ID="${5:-}"
PROJECT_NAME="${6:-}"
MANAGEMENT_GROUP_ID="${7:-}"
WORKLOAD="${8:-}"
WORKLOAD_ALIAS="${9:-}"
ENVIRONMENT="${10:-}"
LOCATION_CODE="${11:-}"
INSTANCE_NUMBER="${12:-}"
OWNER="${13:-}"
MANAGED_BY="${14:-}"
BUILD_NUMBER="${15:-}"

# Validate billing scope is provided for new subscription creation
if [ -z "$EXISTING_SUB_ID" ] && [ -z "$BILLING_SCOPE" ]; then
  echo "##[error]billingScope is required for new subscription creation but was not provided."
  echo "Please ensure billing variables are set in the variable group:"
  echo "  - billingAccountId (required)"
  echo "  - For MCA: invoiceSectionId and billingProfileId"
  echo "  - For EA: enrollmentAccountId"
  exit 1
fi

# Deployment name for tracking
DEPLOYMENT_NAME="sub-vending-${BUILD_NUMBER}"

echo "Starting subscription vending deployment: ${DEPLOYMENT_NAME}"
if [ -z "$EXISTING_SUB_ID" ]; then
  echo "Creating NEW subscription with billing scope: ${BILLING_SCOPE}"
  echo "Note: Subscription creation is asynchronous and may take 30-90 minutes to complete."
else
  echo "Moving existing subscription to management group."
fi

# Start deployment with --no-wait to avoid blocking on subscription provisioning
az deployment tenant create \
  --name "${DEPLOYMENT_NAME}" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters projectName="$PROJECT_NAME" \
  --parameters managementGroupId="$MANAGEMENT_GROUP_ID" \
  --parameters billingScope="$BILLING_SCOPE" \
  --parameters workload="$WORKLOAD" \
  --parameters workloadAlias="$WORKLOAD_ALIAS" \
  --parameters environment="$ENVIRONMENT" \
  --parameters locationCode="$LOCATION_CODE" \
  --parameters instanceNumber="$INSTANCE_NUMBER" \
  --parameters owner="$OWNER" \
  --parameters managedBy="$MANAGED_BY" \
  --parameters existingSubscriptionId="$EXISTING_SUB_ID" \
  --no-wait

if [ $? -ne 0 ]; then
  echo "##[error]Failed to start deployment"
  exit 1
fi

echo "✓ Deployment started successfully. Polling for completion..."

# Poll deployment status until it completes or times out
# Subscription provisioning can take 30-90 minutes
MAX_WAIT_SECONDS=5400  # 90 minutes
BASE_POLL_INTERVAL=60  # Base check interval: 60 seconds
HEARTBEAT_INTERVAL=300 # Log heartbeat every 5 minutes
ELAPSED=0
LAST_STATUS=""
LAST_HEARTBEAT=0
POLL_INTERVAL=$BASE_POLL_INTERVAL
RATE_LIMIT_DETECTED=false
RATE_LIMIT_COUNT=0
MAX_RATE_LIMIT_BACKOFF=600  # Maximum backoff: 10 minutes

# Function to check for rate limiting (HTTP 429) in deployment operations
check_rate_limiting() {
  local deployment_name=$1
  # Query deployment operations and filter for 429 status codes using jq
  local operations=$(az rest --method GET \
    --url "https://management.azure.com/providers/Microsoft.Resources/deployments/${deployment_name}/operations?api-version=2022-09-01" \
    --output json 2>/dev/null | jq '[.value[]? | select(.properties.statusCode == 429)]' 2>/dev/null || echo "[]")
  
  if [ "$operations" != "[]" ] && [ -n "$operations" ]; then
    local count=$(echo "$operations" | jq 'length' 2>/dev/null || echo "0")
    if [ "$count" -gt 0 ]; then
      return 0  # Rate limiting detected
    fi
  fi
  return 1  # No rate limiting
}

while [ $ELAPSED -lt $MAX_WAIT_SECONDS ]; do
  # Get current deployment status
  STATUS=$(az deployment tenant show \
    --name "${DEPLOYMENT_NAME}" \
    --query "properties.provisioningState" \
    --output tsv 2>/dev/null || echo "Unknown")

  # Check for rate limiting in deployment operations
  if check_rate_limiting "${DEPLOYMENT_NAME}"; then
    if [ "$RATE_LIMIT_DETECTED" = false ]; then
      echo "##[warning]Rate limiting (HTTP 429) detected in deployment operations"
      echo "Azure is throttling requests. This is normal for subscription creation."
      echo "Implementing exponential backoff to reduce request frequency..."
      RATE_LIMIT_DETECTED=true
    fi
    
    RATE_LIMIT_COUNT=$((RATE_LIMIT_COUNT + 1))
    # Exponential backoff: 60s, 120s, 240s, 480s, max 600s (10 minutes)
    NEW_INTERVAL=$((BASE_POLL_INTERVAL * (2 ** (RATE_LIMIT_COUNT - 1))))
    if [ $NEW_INTERVAL -gt $MAX_RATE_LIMIT_BACKOFF ]; then
      NEW_INTERVAL=$MAX_RATE_LIMIT_BACKOFF
    fi
    
    if [ $NEW_INTERVAL -gt $POLL_INTERVAL ]; then
      POLL_INTERVAL=$NEW_INTERVAL
      MINUTES=$((POLL_INTERVAL / 60))
      echo "##[warning]Rate limiting persists. Increasing poll interval to ${MINUTES} minutes"
      echo "This helps avoid further throttling. Deployment will continue automatically."
    fi
  else
    # No rate limiting detected - reset if we were backing off
    if [ "$RATE_LIMIT_DETECTED" = true ]; then
      echo "##[info]Rate limiting cleared. Resetting to normal poll interval"
      RATE_LIMIT_DETECTED=false
      RATE_LIMIT_COUNT=0
      POLL_INTERVAL=$BASE_POLL_INTERVAL
    fi
  fi

  # Log when status changes
  if [ "$STATUS" != "$LAST_STATUS" ]; then
    if [ "$RATE_LIMIT_DETECTED" = true ]; then
      echo "Deployment status: ${STATUS} (elapsed: ${ELAPSED}s / ${MAX_WAIT_SECONDS}s) [Rate limited - polling every ${POLL_INTERVAL}s]"
    else
      echo "Deployment status: ${STATUS} (elapsed: ${ELAPSED}s / ${MAX_WAIT_SECONDS}s)"
    fi
    LAST_STATUS="$STATUS"
    LAST_HEARTBEAT=$ELAPSED
  # Log heartbeat periodically even if status hasn't changed (every 5 minutes)
  elif [ $((ELAPSED - LAST_HEARTBEAT)) -ge $HEARTBEAT_INTERVAL ]; then
    MINUTES=$((ELAPSED / 60))
    if [ "$RATE_LIMIT_DETECTED" = true ]; then
      echo "##[debug]Still polling... Status: ${STATUS} (${MINUTES} minutes elapsed) [Rate limited - polling every ${POLL_INTERVAL}s]"
    else
      echo "##[debug]Still polling... Status: ${STATUS} (${MINUTES} minutes elapsed)"
    fi
    LAST_HEARTBEAT=$ELAPSED
  fi

  # Check if deployment completed
  if [ "$STATUS" == "Succeeded" ]; then
    echo "##[section]✓ Deployment completed successfully!"
    
    if [ "$RATE_LIMIT_DETECTED" = true ]; then
      echo "Note: Deployment completed despite rate limiting. Azure automatically retried operations."
    fi
    
    # Get deployment outputs for logging
    OUTPUTS=$(az deployment tenant show \
      --name "${DEPLOYMENT_NAME}" \
      --query "properties.outputs" \
      --output json 2>/dev/null || echo "{}")
    
    if [ "$OUTPUTS" != "{}" ] && [ -n "$OUTPUTS" ]; then
      echo "Deployment outputs:"
      echo "$OUTPUTS" | jq '.' 2>/dev/null || echo "$OUTPUTS"
    fi
    
    exit 0
  elif [ "$STATUS" == "Failed" ]; then
    echo "##[error]Deployment failed!"
    
    # Check if failure was due to rate limiting
    if [ "$RATE_LIMIT_DETECTED" = true ]; then
      echo "##[warning]Rate limiting was detected during deployment. This may have contributed to the failure."
      echo "Consider waiting longer or reducing concurrent subscription creation operations."
    fi
    
    # Get error details
    ERROR=$(az deployment tenant show \
      --name "${DEPLOYMENT_NAME}" \
      --query "properties.error" \
      --output json 2>/dev/null || echo "{}")
    
    if [ "$ERROR" != "{}" ] && [ -n "$ERROR" ]; then
      echo "Error details:"
      echo "$ERROR" | jq '.' 2>/dev/null || echo "$ERROR"
    fi
    
    # Also check operations for detailed error info
    echo "Checking deployment operations for additional details..."
    OPERATIONS=$(az rest --method GET \
      --url "https://management.azure.com/providers/Microsoft.Resources/deployments/${DEPLOYMENT_NAME}/operations?api-version=2022-09-01" \
      --query "value[?properties.provisioningState == 'Failed']" \
      --output json 2>/dev/null || echo "[]")
    
    if [ "$OPERATIONS" != "[]" ] && [ -n "$OPERATIONS" ]; then
      echo "Failed operations:"
      echo "$OPERATIONS" | jq '.[] | {Resource: .properties.targetResource.resourceName, StatusCode: .properties.statusCode, StatusMessage: .properties.statusMessage}' 2>/dev/null || echo "$OPERATIONS"
    fi
    
    exit 1
  elif [ "$STATUS" == "Canceled" ]; then
    echo "##[error]Deployment was canceled"
    exit 1
  fi

  # Wait before next poll (using dynamic interval)
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

# Timeout reached
echo "##[error]Deployment did not complete within ${MAX_WAIT_SECONDS} seconds (90 minutes)"
echo "Current status: ${STATUS}"

if [ "$RATE_LIMIT_DETECTED" = true ]; then
  echo "##[warning]Rate limiting (HTTP 429) was detected during deployment."
  echo "Azure was throttling requests, which may have extended the deployment time."
  echo "The deployment may still be in progress. Azure will continue retrying automatically."
  echo ""
  echo "Recommendations:"
  echo "  1. Check Azure Portal for current deployment status"
  echo "  2. Wait longer before retrying (rate limits reset over time)"
  echo "  3. Reduce concurrent subscription creation operations"
  echo "  4. Consider creating subscriptions during off-peak hours"
else
  echo "The deployment may still be in progress. Check Azure Portal for current status."
fi

echo "Deployment name: ${DEPLOYMENT_NAME}"
exit 1
