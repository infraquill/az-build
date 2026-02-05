#!/usr/bin/env bash
#
# defs-deploy.sh
# Location: code/pipelines/policy-definitions/
#
# Deploys the custom policy definitions at management group scope.
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
#     <managedBy>
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

az deployment mg create \
  --name "$DEPLOYMENT_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters environment="$ENVIRONMENT" \
  --parameters location="$LOCATION" \
  --parameters owner="$OWNER" \
  --parameters managedBy="$MANAGED_BY"
