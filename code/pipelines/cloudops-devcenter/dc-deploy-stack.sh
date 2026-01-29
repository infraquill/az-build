#!/usr/bin/env bash
#
# dc-deploy-stack.sh
# Location: code/pipelines/cloudops-devcenter/
#
# Deploys the DevCenter deployment stack at subscription scope.
#
# Usage:
#   bash dc-deploy-stack.sh \
#     <subscriptionId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <actionOnUnmanage> \
#     <workloadAlias> \
#     <environment> \
#     <locationCode> \
#     <instanceNumber> \
#     <location> \
#     <owner> \
#     <managedBy> \
#     <subnetResourceId> \
#     <logAnalyticsWorkspaceResourceId>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed

set -euo pipefail

# Parameters (same as validate)
SUBSCRIPTION_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ACTION_ON_UNMANAGE="${7:-}"
WORKLOAD_ALIAS="${8:-}"
ENVIRONMENT="${9:-}"
LOCATION_CODE="${10:-}"
INSTANCE_NUMBER="${11:-}"
LOCATION="${12:-}"
OWNER="${13:-}"
MANAGED_BY="${14:-}"
SUBNET_RESOURCE_ID="${15:-}"
LOG_ANALYTICS_WORKSPACE_RESOURCE_ID="${16:-}"

PARAMS=""
# Core naming parameters
if [ -n "$WORKLOAD_ALIAS" ]; then
  PARAMS="$PARAMS --parameters workloadAlias='$WORKLOAD_ALIAS'"
fi
if [ -n "$ENVIRONMENT" ]; then
  PARAMS="$PARAMS --parameters environment='$ENVIRONMENT'"
fi
if [ -n "$LOCATION_CODE" ]; then
  PARAMS="$PARAMS --parameters locationCode='$LOCATION_CODE'"
fi
if [ -n "$INSTANCE_NUMBER" ]; then
  PARAMS="$PARAMS --parameters instanceNumber='$INSTANCE_NUMBER'"
fi
if [ -n "$LOCATION" ]; then
  PARAMS="$PARAMS --parameters location='$LOCATION'"
fi
# Ownership
if [ -n "$OWNER" ]; then
  PARAMS="$PARAMS --parameters owner='$OWNER'"
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS="$PARAMS --parameters managedBy='$MANAGED_BY'"
fi
# Spoke networking references
if [ -n "$SUBNET_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters subnetResourceId='$SUBNET_RESOURCE_ID'"
fi
# Monitoring
if [ -n "$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters logAnalyticsWorkspaceResourceId='$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'"
fi

az stack sub create \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes \
  $PARAMS
