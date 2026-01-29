#!/usr/bin/env bash
#
# lookup-subscription.sh
# Location: code/pipelines/templates/
#
# Reusable script that looks up an existing Azure subscription by its alias name
# (display name) and returns its ID.
#
# Usage:
#   bash lookup-subscription.sh <subscriptionAliasName>
#
# Parameters:
#   subscriptionAliasName - The subscription alias/display name to search for
#
# Output:
#   Sets Azure DevOps pipeline variables:
#   - EXISTING_SUBSCRIPTION_ID: The subscription ID (GUID) if found, empty if not
#   - SUBSCRIPTION_ALIAS_NAME: The subscription alias name that was searched
#
# Example:
#   bash lookup-subscription.sh "subcr-hub-prod-cac-001"
#

set -euo pipefail

# Parameters
SUBSCRIPTION_ALIAS_NAME="${1:-}"

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ALIAS_NAME" ]]; then
    echo "##[error]Missing required parameter: subscriptionAliasName"
    echo "Usage: bash lookup-subscription.sh <subscriptionAliasName>"
    exit 1
fi

echo "Looking for existing subscription with name: ${SUBSCRIPTION_ALIAS_NAME}"

# Query Azure for a subscription with this display name
# Using --query to filter by displayName and return the subscriptionId
EXISTING_SUBSCRIPTION_ID=$(az account list \
    --query "[?name=='${SUBSCRIPTION_ALIAS_NAME}'].id" \
    --output tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_SUBSCRIPTION_ID" ]]; then
    echo "✓ Found existing subscription: ${SUBSCRIPTION_ALIAS_NAME}"
    echo "  Subscription ID: ${EXISTING_SUBSCRIPTION_ID}"
    
    # Set Azure DevOps pipeline variable
    echo "##vso[task.setvariable variable=EXISTING_SUBSCRIPTION_ID;isOutput=true]${EXISTING_SUBSCRIPTION_ID}"
else
    echo "✓ No existing subscription found with name: ${SUBSCRIPTION_ALIAS_NAME}"
    echo "  A new subscription will be created."
    
    # Set empty variable for pipeline
    echo "##vso[task.setvariable variable=EXISTING_SUBSCRIPTION_ID;isOutput=true]"
fi

# Also output the alias name for reference
echo "##vso[task.setvariable variable=SUBSCRIPTION_ALIAS_NAME;isOutput=true]${SUBSCRIPTION_ALIAS_NAME}"
