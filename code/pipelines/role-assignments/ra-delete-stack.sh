#!/usr/bin/env bash
#
# ra-delete-stack.sh
# Location: code/pipelines/role-assignments/
#
# Deletes the Role Assignments stack.
#

set -euo pipefail

MANAGEMENT_GROUP_ID="${1:-}"
STACK_NAME="${2:-}"
ACTION_ON_UNMANAGE="${3:-}"

az stack mg delete \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes
