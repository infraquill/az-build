#!/usr/bin/env bash
#
# ra-validate-stack.sh
# Location: code/pipelines/role-assignments/
#
# Validates the Role Assignments template.
#

set -euo pipefail

# Parameters (same as deploy)
MANAGEMENT_GROUP_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ENVIRONMENT="${7:-}"
OWNER="${8:-}"
MANAGED_BY="${9:-}"

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

az stack mg validate \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  $PARAMS
