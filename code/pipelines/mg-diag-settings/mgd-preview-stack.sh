#!/usr/bin/env bash
#
# mgd-preview-stack.sh
# Location: code/pipelines/mg-diag-settings/
#
# Previews the management group diagnostic settings deployment stack state.
#
# Usage:
#   bash mgd-preview-stack.sh \
#     <managementGroupId> \
#     <stackName>
#

set -uo pipefail

# Parameters
MANAGEMENT_GROUP_ID="${1:-}"
STACK_NAME="${2:-}"

echo "Stack: ${STACK_NAME}"

if az stack mg show --name "${STACK_NAME}" --management-group-id "$MANAGEMENT_GROUP_ID" -o none 2>/dev/null; then
  echo "Status: Stack exists - will be updated"
  # Show managed resources
  az stack mg show --name "${STACK_NAME}" --management-group-id "$MANAGEMENT_GROUP_ID" \
    --query "resources[].id" -o tsv 2>/dev/null | sed 's/^/  /' || true
else
  echo "Status: Stack does not exist - will be created"
fi
