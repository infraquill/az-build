#!/usr/bin/env bash
#
# roles-whatif-deployment.sh
# Location: code/pipelines/role-definitions/
#
# Runs What-If analysis for custom role definitions at management group scope.
#
# Usage:
#   bash gov-whatif-deployment.sh \
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
#   0 - What-if analysis succeeded
#   1 - What-if analysis failed

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

az deployment mg what-if \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters environment="$ENVIRONMENT" \
  --parameters location="$LOCATION" \
  --parameters owner="$OWNER" \
  --parameters managedBy="$MANAGED_BY"
