#!/usr/bin/env bash
#
# mon-preview-stack.sh
# Location: code/pipelines/monitoring/
#
# Previews the monitoring deployment stack state at subscription scope.
# Shows current state for review (deployment stacks don't support what-if).
#
# Usage:
#   bash mon-preview-stack.sh \
#     <monitoringSubscriptionId> \
#     <stackName>
#
# Exit codes:
#   0 - Preview succeeded
#   1 - Preview failed

set -uo pipefail

# Parameters
MONITORING_SUBSCRIPTION_ID="${1:-}"
STACK_NAME="${2:-}"

# Note: Deployment stacks don't support what-if. This stage shows current state for review.
echo "Stack: ${STACK_NAME}"
echo ""

if az stack sub show --name "${STACK_NAME}" --subscription "$MONITORING_SUBSCRIPTION_ID" -o none 2>/dev/null; then
  echo "Status: Stack exists - will be updated"
  echo ""
  echo "Current managed resources:"
  az stack sub show --name "${STACK_NAME}" --subscription "$MONITORING_SUBSCRIPTION_ID" \
    --query "resources[].id" -o tsv 2>/dev/null | sed 's/^/  /' || true
else
  echo "Status: Stack does not exist - will be created"
fi
