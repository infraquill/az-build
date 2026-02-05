#!/usr/bin/env bash
#
# ra-deploy-stack.sh
# Location: code/pipelines/role-assignments/
#
# Deploys the Role Assignments at Management Group scope.
#
# Usage:
#   bash ra-deploy-stack.sh \
#     <managementGroupId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <environment> \
#     <owner> \
#     <managedBy>
#

set -euo pipefail

# Parameters
MANAGEMENT_GROUP_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ENVIRONMENT="${7:-}"
OWNER="${8:-}"
MANAGED_BY="${9:-}"

# Parameter overrides
PARAMS=""
if [ -n "$ENVIRONMENT" ]; then
  PARAMS="$PARAMS --parameters environment=$ENVIRONMENT"
fi
if [ -n "$OWNER" ]; then
  PARAMS="$PARAMS --parameters owner=$OWNER"
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS="$PARAMS --parameters managedBy=$MANAGED_BY"
fi

az stack mg create \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --yes \
  $PARAMS
