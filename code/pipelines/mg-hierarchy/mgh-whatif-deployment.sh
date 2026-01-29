#!/usr/bin/env bash
#
# mgh-whatif-deployment.sh
# Location: code/pipelines/mg-hierarchy/
#
# Runs what-if analysis for the management group hierarchy deployment at tenant scope.
#
# Usage:
#   bash mgh-whatif-deployment.sh \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <tenantRootManagementGroupId> \
#     <orgName> \
#     <orgDisplayName>
#
# Exit codes:
#   0 - What-if analysis succeeded
#   1 - What-if analysis failed

set -euo pipefail

# Parameters
TEMPLATE_FILE="${1:-}"
PARAMETERS_FILE="${2:-}"
DEPLOYMENT_LOCATION="${3:-}"
TENANT_ROOT_MG_ID="${4:-}"
ORG_NAME="${5:-}"
ORG_DISPLAY_NAME="${6:-}"

az deployment tenant what-if \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters tenantRootManagementGroupId="$TENANT_ROOT_MG_ID" \
  --parameters orgName="$ORG_NAME" \
  --parameters orgDisplayName="$ORG_DISPLAY_NAME"
