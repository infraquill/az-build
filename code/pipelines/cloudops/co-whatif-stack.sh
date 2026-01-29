#!/usr/bin/env bash
#
# co-whatif-stack.sh
# Location: code/pipelines/cloudops/
#
# Runs what-if analysis for the CloudOps deployment stack at subscription scope.
#
# Usage:
#   bash co-whatif-stack.sh \
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
#     <devCenterResourceId> \
#     <poolSubnetResourceId> \
#     <poolMaximumConcurrency> \
#     <poolAgentSkuName> \
#     <poolImageName> \
#     <enableScaleToZero> \
#     <azureDevOpsOrganizationUrl> \
#     <azureDevOpsProjectNames>
#
# Exit codes:
#   0 - What-if analysis succeeded
#   1 - What-if analysis failed

set -euo pipefail

# Parameters
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
DEVCENTER_RESOURCE_ID="${15:-}"
POOL_SUBNET_RESOURCE_ID="${16:-}"
POOL_MAXIMUM_CONCURRENCY="${17:-}"
POOL_AGENT_SKU_NAME="${18:-}"
POOL_IMAGE_NAME="${19:-}"
ENABLE_SCALE_TO_ZERO="${20:-}"
AZURE_DEVOPS_ORG_URL="${21:-}"
AZURE_DEVOPS_PROJECT_NAMES="${22:-}"

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
# DevCenter references
if [ -n "$DEVCENTER_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters devCenterResourceId='$DEVCENTER_RESOURCE_ID'"
fi
# Spoke networking references
if [ -n "$POOL_SUBNET_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters poolSubnetResourceId='$POOL_SUBNET_RESOURCE_ID'"
fi
# Managed DevOps Pool Configuration
PARAMS="$PARAMS --parameters poolMaximumConcurrency=$POOL_MAXIMUM_CONCURRENCY"
if [ -n "$POOL_AGENT_SKU_NAME" ]; then
  PARAMS="$PARAMS --parameters poolAgentSkuName='$POOL_AGENT_SKU_NAME'"
fi
if [ -n "$POOL_IMAGE_NAME" ]; then
  PARAMS="$PARAMS --parameters poolImageName='$POOL_IMAGE_NAME'"
fi
PARAMS="$PARAMS --parameters enableScaleToZero=$ENABLE_SCALE_TO_ZERO"
# Azure DevOps Configuration
if [ -n "$AZURE_DEVOPS_ORG_URL" ]; then
  PARAMS="$PARAMS --parameters azureDevOpsOrganizationUrl='$AZURE_DEVOPS_ORG_URL'"
fi
# Handle project names as array
if [ -n "$AZURE_DEVOPS_PROJECT_NAMES" ]; then
  # Convert comma-separated string to JSON array
  PROJECT_ARRAY=$(echo "$AZURE_DEVOPS_PROJECT_NAMES" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
  PARAMS="$PARAMS --parameters azureDevOpsProjectNames='$PROJECT_ARRAY'"
fi

az stack sub create \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --what-if \
  $PARAMS
