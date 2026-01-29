#!/usr/bin/env bash
#
# mgh-deploy.sh
# Location: code/pipelines/mg-hierarchy/
#
# Deploys the management group hierarchy at tenant scope.
#
# Usage:
#   bash mgh-deploy.sh \
#     <deploymentName> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <tenantRootManagementGroupId> \
#     <orgName> \
#     <orgDisplayName>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed

set -euo pipefail

# Parameters
DEPLOYMENT_NAME="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
TENANT_ROOT_MG_ID="${5:-}"
ORG_NAME="${6:-}"
ORG_DISPLAY_NAME="${7:-}"

az deployment tenant create \
  --name "$DEPLOYMENT_NAME" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters tenantRootManagementGroupId="$TENANT_ROOT_MG_ID" \
  --parameters orgName="$ORG_NAME" \
  --parameters orgDisplayName="$ORG_DISPLAY_NAME"
