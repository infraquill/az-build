#!/usr/bin/env bash
#
# gov-deploy.sh
# Location: code/pipelines/governance/
#
# Deploys the governance policies at management group scope.
#
# Usage:
#   bash gov-deploy.sh \
#     <deploymentName> \
#     <managementGroupId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <environment> \
#     <location> \
#     <owner> \
#     <managedBy> \
#     <enableMCSB> \
#     <enableCanadaPBMM>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed

set -euo pipefail

# Parameters
DEPLOYMENT_NAME="${1:-}"
MANAGEMENT_GROUP_ID="${2:-}"
TEMPLATE_FILE="${3:-}"
PARAMETERS_FILE="${4:-}"
DEPLOYMENT_LOCATION="${5:-}"
ENVIRONMENT="${6:-}"
LOCATION="${7:-}"
OWNER="${8:-}"
MANAGED_BY="${9:-}"
ENABLE_MCSB="${10:-}"
ENABLE_CANADA_PBMM="${11:-}"
ENFORCEMENT_MODE="${12:-}"

az deployment mg create \
  --name "$DEPLOYMENT_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters environment="$ENVIRONMENT" \
  --parameters location="$LOCATION" \
  --parameters owner="$OWNER" \
  --parameters managedBy="$MANAGED_BY" \
  --parameters enableMCSB=$ENABLE_MCSB \
  --parameters enableCanadaPBMM=$ENABLE_CANADA_PBMM \
  --parameters enforcementMode=$ENFORCEMENT_MODE
