#!/usr/bin/env bash
#
# mgd-validate-stack.sh
# Location: code/pipelines/mg-diag-settings/
#
# Validates the management group diagnostic settings deployment stack.
#
# Usage:
#   bash mgd-validate-stack.sh \
#     <managementGroupId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <actionOnUnmanage> \
#     <topLevelManagementGroupPrefix> \
#     <topLevelManagementGroupSuffix> \
#     <logAnalyticsWorkspaceResourceId>
#

set -euo pipefail

MANAGEMENT_GROUP_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ACTION_ON_UNMANAGE="${7:-}"
TOP_LEVEL_PREFIX="${8:-}"
TOP_LEVEL_SUFFIX="${9:-}"
LAW_RESOURCE_ID="${10:-}"

PARAMS=""
if [ -n "$TOP_LEVEL_PREFIX" ]; then
    PARAMS="$PARAMS --parameters parTopLevelManagementGroupPrefix=$TOP_LEVEL_PREFIX"
fi
if [ -n "$TOP_LEVEL_SUFFIX" ]; then
    PARAMS="$PARAMS --parameters parTopLevelManagementGroupSuffix=$TOP_LEVEL_SUFFIX"
fi
if [ -n "$LAW_RESOURCE_ID" ]; then
    PARAMS="$PARAMS --parameters parLogAnalyticsWorkspaceResourceId=$LAW_RESOURCE_ID"
fi

az stack mg validate \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  $PARAMS
