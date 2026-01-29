#!/usr/bin/env bash
#
# hub-delete-stack.sh
# Location: code/pipelines/hub/
#
# Deletes the hub deployment stack at subscription scope.
# Resources are handled based on the stack's action-on-unmanage setting
# (typically detachAll, meaning resources are kept but no longer managed).
#
# Usage:
#   bash hub-delete-stack.sh \
#     <subscriptionId> \
#     <stackName> \
#     <actionOnUnmanage>
#
# Exit codes:
#   0 - Deletion succeeded
#   1 - Deletion failed

set -euo pipefail

# Parameters
SUBSCRIPTION_ID="${1:-}"
STACK_NAME="${2:-}"
ACTION_ON_UNMANAGE="${3:-detachAll}"

# Validate required parameters
if [ -z "$SUBSCRIPTION_ID" ]; then
  echo "##[error]Subscription ID is required."
  exit 1
fi

if [ -z "$STACK_NAME" ]; then
  echo "##[error]Stack name is required."
  exit 1
fi

echo "=============================================="
echo "Deleting Hub Deployment Stack"
echo "=============================================="
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Stack Name: $STACK_NAME"
echo "Action on Unmanage: $ACTION_ON_UNMANAGE"
echo "=============================================="

# Check if the stack exists
if ! az stack sub show --name "$STACK_NAME" --subscription "$SUBSCRIPTION_ID" -o none 2>/dev/null; then
  echo "##[warning]Stack '$STACK_NAME' does not exist in subscription '$SUBSCRIPTION_ID'. Nothing to delete."
  exit 0
fi

# Show stack info before deletion
echo ""
echo "Stack details before deletion:"
az stack sub show --name "$STACK_NAME" --subscription "$SUBSCRIPTION_ID" \
  --query "{name:name, provisioningState:provisioningState, actionOnUnmanage:actionOnUnmanage}" \
  -o table

echo ""
echo "Deleting stack..."

az stack sub delete \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes

echo ""
echo "✓ Stack '$STACK_NAME' deleted successfully."
echo "  Note: Resources were handled according to the stack's action-on-unmanage setting."
