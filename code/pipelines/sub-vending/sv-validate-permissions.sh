#!/usr/bin/env bash
#
# sv-validate-permissions.sh
# Location: code/pipelines/sub-vending/
#
# Validates that the service principal has the required permissions for
# subscription creation. Only validates when creating new subscriptions.
#
# Usage:
#   bash sv-validate-permissions.sh <existingSubscriptionId>
#
# Parameters:
#   existingSubscriptionId - The ID of an existing subscription (empty if creating new)
#
# Exit codes:
#   0 - Permissions are valid or validation skipped
#   1 - Missing required permissions

set -euo pipefail

# Parameters
EXISTING_SUB_ID="${1:-}"

# Only validate permissions when creating new subscriptions
if [ -z "$EXISTING_SUB_ID" ]; then
  echo "Validating permissions for new subscription creation..."
  
  # Get current service principal object ID
  SP_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query user.name -o tsv)
  if [ -z "$SP_OBJECT_ID" ]; then
    echo "##[warning]Could not determine service principal identity. Skipping permission validation."
    exit 0
  fi
  
  # Get tenant root management group
  TENANT_ROOT_MG=$(az account management-group list \
    --query "[?displayName=='Tenant Root Group'].name" -o tsv 2>/dev/null || echo "")
  
  if [ -z "$TENANT_ROOT_MG" ]; then
    echo "##[warning]Could not determine tenant root management group. Skipping permission validation."
    exit 0
  fi
  
  # Check for Owner role at Tenant Root MG
  echo "Checking for Owner role at Tenant Root MG..."
  HAS_OWNER=$(az role assignment list \
    --assignee "$SP_OBJECT_ID" \
    --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG" \
    --query "[?roleDefinitionName=='Owner']" -o tsv 2>/dev/null || echo "")
  
  if [ -z "$HAS_OWNER" ]; then
    echo "##[error]Missing required permission: Owner role at Tenant Root Management Group"
    echo "Service principal needs Owner role at: /providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG"
    echo "Assign with: az role assignment create --assignee <sp-object-id> --role Owner --scope \"/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG\""
    exit 1
  fi
  echo "✓ Owner role at Tenant Root MG: OK"
  
  # Note: Billing permissions cannot be easily validated via CLI
  # They must be assigned via Azure Portal and are required for subscription creation
  echo "##[warning]Billing permissions cannot be validated via CLI."
  echo "Ensure service principal has billing permissions assigned via Azure Portal:"
  echo "  - For MCA: Invoice Section Contributor"
  echo "  - For EA: Enrollment Account Administrator"
  echo "Missing billing permissions will cause deployment to hang or fail."
else
  echo "Existing subscription detected - skipping permission validation."
fi
