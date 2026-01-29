#!/usr/bin/env bash
#
# compute-resource-alias.sh
# Location: code/pipelines/templates/
#
# Reusable script that computes a resource alias name based on the standard
# naming convention: {resourceTypeCode}-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}
#
# Usage:
#   bash compute-resource-alias.sh <resourceTypeCode> <workloadAlias> <environment> <locationCode> <instanceNumber>
#
# Parameters:
#   resourceTypeCode - The resource type code (e.g., subcr, rg, vnet, etc.)
#   workloadAlias    - The workload alias (e.g., hub, spoke, app)
#   environment      - The environment (e.g., dev, prod)
#   locationCode     - The location code (e.g., cac for Canada Central)
#   instanceNumber   - The instance number (e.g., 001)
#
# Output:
#   Sets Azure DevOps pipeline variable: RESOURCE_ALIAS
#   Format: {resourceTypeCode}-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}
#
# Example:
#   bash compute-resource-alias.sh "subcr" "hub" "prod" "cac" "001"
#   # Output: subcr-hub-prod-cac-001
#

set -euo pipefail

# Parameters
RESOURCE_TYPE_CODE="${1:-}"
WORKLOAD_ALIAS="${2:-}"
ENVIRONMENT="${3:-}"
LOCATION_CODE="${4:-}"
INSTANCE_NUMBER="${5:-}"

# Validate required parameters
if [[ -z "$RESOURCE_TYPE_CODE" || -z "$WORKLOAD_ALIAS" || -z "$ENVIRONMENT" || -z "$LOCATION_CODE" || -z "$INSTANCE_NUMBER" ]]; then
    echo "##[error]Missing required parameters."
    echo "Usage: bash compute-resource-alias.sh <resourceTypeCode> <workloadAlias> <environment> <locationCode> <instanceNumber>"
    exit 1
fi

# Convert to lowercase for consistency
RESOURCE_TYPE_CODE=$(echo "$RESOURCE_TYPE_CODE" | tr '[:upper:]' '[:lower:]')
WORKLOAD_ALIAS=$(echo "$WORKLOAD_ALIAS" | tr '[:upper:]' '[:lower:]')
ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')
LOCATION_CODE=$(echo "$LOCATION_CODE" | tr '[:upper:]' '[:lower:]')

# Compute the resource alias name
# Convention: {resourceTypeCode}-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}
RESOURCE_ALIAS="${RESOURCE_TYPE_CODE}-${WORKLOAD_ALIAS}-${ENVIRONMENT}-${LOCATION_CODE}-${INSTANCE_NUMBER}"

echo "✓ Computed resource alias: ${RESOURCE_ALIAS}"

# Set Azure DevOps pipeline variable
echo "##vso[task.setvariable variable=RESOURCE_ALIAS;isOutput=true]${RESOURCE_ALIAS}"
