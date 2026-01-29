#!/usr/bin/env bash
#
# sv-construct-billing-scope.sh
# Location: code/pipelines/sub-vending/
#
# Constructs the billing scope from variable group values.
# Supports both MCA (Modern Commerce Agreement) and EA (Enterprise Agreement) formats.
#
# Usage:
#   bash sv-construct-billing-scope.sh <billingAccountId> <invoiceSectionId> <billingProfileId> <enrollmentAccountId>
#
# Parameters:
#   billingAccountId - The billing account ID (required)
#   invoiceSectionId - The invoice section ID (for MCA)
#   billingProfileId - The billing profile ID (for MCA)
#   enrollmentAccountId - The enrollment account ID (for EA)
#
# Output:
#   Sets Azure DevOps pipeline variable: BILLING_SCOPE
#   - MCA format: /providers/Microsoft.Billing/billingAccounts/{id}/billingProfiles/{id}/invoiceSections/{id}
#   - EA format: /providers/Microsoft.Billing/billingAccounts/{id}/enrollmentAccounts/{id}
#   - Empty string if billing account ID is not provided

set -euo pipefail

# Parameters
BILLING_ACCOUNT_ID="${1:-}"
INVOICE_SECTION_ID="${2:-}"
BILLING_PROFILE_ID="${3:-}"
ENROLLMENT_ACCOUNT_ID="${4:-}"

BILLING_SCOPE=""

if [ -n "$BILLING_ACCOUNT_ID" ]; then
  if [ -n "$INVOICE_SECTION_ID" ] && [ -n "$BILLING_PROFILE_ID" ]; then
    # MCA billing scope format (requires billing profile)
    BILLING_SCOPE="/providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_ID}/billingProfiles/${BILLING_PROFILE_ID}/invoiceSections/${INVOICE_SECTION_ID}"
  elif [ -n "$ENROLLMENT_ACCOUNT_ID" ]; then
    # EA billing scope format
    BILLING_SCOPE="/providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_ID}/enrollmentAccounts/${ENROLLMENT_ACCOUNT_ID}"
  fi
fi

# Set Azure DevOps pipeline variable
echo "##vso[task.setvariable variable=BILLING_SCOPE;isOutput=true]${BILLING_SCOPE}"

if [ -n "$BILLING_SCOPE" ]; then
  echo "✓ Billing scope constructed: ${BILLING_SCOPE}"
else
  echo "⚠ No billing scope constructed (billing account ID not provided or incomplete)"
fi
