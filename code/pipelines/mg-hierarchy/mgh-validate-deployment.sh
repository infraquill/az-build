#!/usr/bin/env bash
#
# mgh-validate-deployment.sh
# Location: code/pipelines/mg-hierarchy/
#
# Validates the management group hierarchy deployment at tenant scope.
#
# Usage:
#   bash mgh-validate-deployment.sh \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <tenantRootManagementGroupId> \
#     <orgName> \
#     <orgDisplayName>
#
# Exit codes:
#   0 - Validation succeeded
#   1 - Validation failed

set -euo pipefail

# Parameters
TEMPLATE_FILE="${1:-}"
PARAMETERS_FILE="${2:-}"
DEPLOYMENT_LOCATION="${3:-}"
TENANT_ROOT_MG_ID="${4:-}"
ORG_NAME="${5:-}"
ORG_DISPLAY_NAME="${6:-}"

az deployment tenant validate \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters tenantRootManagementGroupId="$TENANT_ROOT_MG_ID" \
  --parameters orgName="$ORG_NAME" \
  --parameters orgDisplayName="$ORG_DISPLAY_NAME"
