#!/usr/bin/env bash
#
# sv-whatif-deployment.sh
# Location: code/pipelines/sub-vending/
#
# Runs a what-if analysis for the subscription vending Bicep deployment at tenant scope.
#
# Usage:
#   bash sv-whatif-deployment.sh \
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
#     <managedBy>
#
# Exit codes:
#   0 - What-if analysis succeeded
#   1 - What-if analysis failed

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

az deployment tenant what-if \
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
  --parameters existingSubscriptionId="$EXISTING_SUB_ID"
