#!/usr/bin/env bash
#
# ra-preview-stack.sh
# Location: code/pipelines/role-assignments/
#
# Previews changes for the Role Assignments stack.
#

set -euo pipefail

MANAGEMENT_GROUP_ID="${1:-}"
STACK_NAME="${2:-}"

az stack mg show \
  --name "$STACK_NAME" \
  --management-group-id "$MANAGEMENT_GROUP_ID" \
  --output json
