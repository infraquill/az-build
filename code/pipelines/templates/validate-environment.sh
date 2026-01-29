#!/bin/bash
# =============================================================================
# Validate Environment Parameter
# =============================================================================
# Validates that the provided environment parameter is in the allowed list
# of environments from the common-variables variable group.
#
# Usage:
#   bash validate-environment.sh <allowed_environments> <environment>
#
# Arguments:
#   allowed_environments - Comma-separated list of allowed environments (from $(environments) variable)
#   environment          - The environment parameter to validate
#
# Exit Codes:
#   0 - Environment is valid
#   1 - Environment is invalid or missing
# =============================================================================

set -euo pipefail

ALLOWED_ENVS="${1:-}"
ENV_PARAM="${2:-}"

if [ -z "$ENV_PARAM" ]; then
  echo "##[error]Environment parameter is required but was not provided."
  echo "Allowed environments: ${ALLOWED_ENVS}"
  exit 1
fi

if [[ ",${ALLOWED_ENVS}," =~ ",${ENV_PARAM}," ]]; then
  echo "✓ Valid environment: ${ENV_PARAM}"
else
  echo "##[error]Invalid environment: ${ENV_PARAM}"
  echo "Allowed environments: ${ALLOWED_ENVS}"
  exit 1
fi
