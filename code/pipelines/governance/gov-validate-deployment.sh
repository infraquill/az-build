#!/usr/bin/env bash
#
# gov-validate-deployment.sh
# Location: code/pipelines/governance/
#
# Validates the governance deployment at management group scope.
#
# Usage:
#   bash gov-validate-deployment.sh \
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
#   0 - Validation succeeded
#   1 - Validation failed

set -euo pipefail

# Parameters
MANAGEMENT_GROUP_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
ENVIRONMENT="${5:-}"
LOCATION="${6:-}"
OWNER="${7:-}"
MANAGED_BY="${8:-}"
ENABLE_MCSB="${9:-}"
ENABLE_CANADA_PBMM="${10:-}"
ENFORCEMENT_MODE="${11:-}"
az deployment mg validate \
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
