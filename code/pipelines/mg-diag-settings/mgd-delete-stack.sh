#!/usr/bin/env bash
#
# mgd-delete-stack.sh
# Location: code/pipelines/mg-diag-settings/
#
# Deletes the management group diagnostic settings deployment stack.
#
# Usage:
#   bash mgd-delete-stack.sh \
#     <managementGroupId> \
#     <stackName> \
#     <actionOnUnmanage>
#

set -euo pipefail

# Parameters
MANAGEMENT_GROUP_ID="${1:-}"
STACK_NAME="${2:-}"
ACTION_ON_UNMANAGE="${3:-detachAll}"

if [ -z "$MANAGEMENT_GROUP_ID" ]; then
  echo "##[error]Management Group ID is required."
  exit 1
fi

if [ -z "$STACK_NAME" ]; then
  echo "##[error]Stack name is required."
  exit 1
fi

echo "Deleting Stack: $STACK_NAME at MG: $MANAGEMENT_GROUP_ID"

if ! az stack mg show --name "$STACK_NAME" --management-group-id "$MANAGEMENT_GROUP_ID" -o none 2>/dev/null; then
  echo "Stack '$STACK_NAME' does not exist. Nothing to delete."
  exit 0
fi

az stack mg delete \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes

echo "Stack '$STACK_NAME' deleted successfully."
