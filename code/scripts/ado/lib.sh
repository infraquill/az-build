#!/bin/bash
# =============================================================================
# NuclearIMS Infrastructure - Shared Library Functions
# =============================================================================
# This file contains utility functions and helper functions used by ADO scripts.
# Scripts that use this library should source both lib.sh and config.sh:
#   source "${SCRIPT_DIR}/lib.sh"    # First: defines functions
#   source "${SCRIPT_DIR}/config.sh" # Second: sets variables used by functions
# =============================================================================

# =============================================================================
# Color Output Helpers
# =============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Log functions output to stderr so they don't interfere with function return values
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1" >&2; }

# =============================================================================
# Management Group Functions
# =============================================================================
# Management Group hierarchy following Azure CAF enterprise-scale pattern
# Using functions for bash 3.x compatibility (macOS default bash)

# Get the parent management group for a given management group
# Usage: parent=$(get_mg_parent "mg-connectivity")
get_mg_parent() {
    local mg_name="$1"
    case "$mg_name" in
        # Root management group (under Tenant Root Group)
        "$ROOT_MG_NAME")   echo "" ;;
        # Top-level management groups (under root)
        mg-platform)       echo "$ROOT_MG_NAME" ;;
        mg-landing-zone)   echo "$ROOT_MG_NAME" ;;
        mg-sandbox)        echo "$ROOT_MG_NAME" ;;
        mg-decommissioned) echo "$ROOT_MG_NAME" ;;
        # Platform management groups
        mg-connectivity)   echo "mg-platform" ;;
        mg-management)     echo "mg-platform" ;;
        # Landing Zone management groups
        mg-online-nonprod) echo "mg-landing-zone" ;;
        mg-online-prod)    echo "mg-landing-zone" ;;
        *)                 echo "" ;;
    esac
}

# Get the display name for a management group
# Usage: display_name=$(get_mg_display_name "mg-connectivity")
get_mg_display_name() {
    local mg_name="$1"
    case "$mg_name" in
        "$ROOT_MG_NAME")   echo "$ROOT_MG_DISPLAY_NAME" ;;
        mg-platform)       echo "Platform" ;;
        mg-connectivity)   echo "Connectivity" ;;
        mg-management)     echo "Management" ;;
        mg-landing-zone)   echo "Landing Zone" ;;
        mg-online-nonprod) echo "Online Non-Prod" ;;
        mg-online-prod)    echo "Online Prod" ;;
        mg-sandbox)        echo "Sandbox" ;;
        mg-decommissioned) echo "Decommissioned" ;;
        *)                 echo "$mg_name" ;;  # Fallback to mg name
    esac
}

# =============================================================================
# Validation Function
# =============================================================================
validate_config() {
    local errors=0
    
    if [[ -z "${TENANT_ID:-}" ]]; then
        log_error "TENANT_ID is not set"
        ((errors++))
    fi
    
    if [[ -z "${ADO_ORGANIZATION_ID:-}" ]]; then
        log_warn "ADO_ORGANIZATION_ID is not set - Azure DevOps automation will be skipped"
    fi
    
    if [[ -z "${ADO_ORGANIZATION:-}" ]]; then
        log_warn "ADO_ORGANIZATION is not set - Azure DevOps automation will be skipped"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Configuration validation failed with $errors error(s)"
        return 1
    fi
    
    log_success "Configuration validated successfully"
    return 0
}

# =============================================================================
# Bootstrap Context Functions
# =============================================================================
# These functions manage the bootstrap subscription context used during setup.
# The context is saved to a local file so subsequent scripts can use it.

# Compute SCRIPT_DIR if not already set (defensive programming)
# This ensures BOOTSTRAP_CONTEXT_FILE always resolves correctly
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    # Try to determine from BASH_SOURCE (works when lib.sh is sourced)
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        # Fallback to current directory (shouldn't happen in normal usage)
        SCRIPT_DIR="$(pwd)"
    fi
fi

# File to store bootstrap context
BOOTSTRAP_CONTEXT_FILE="${SCRIPT_DIR}/.bootstrap-context.env"

# Save bootstrap subscription context to file
save_bootstrap_context() {
    local sub_id=$1
    local context_file="${BOOTSTRAP_CONTEXT_FILE}"
    
    cat > "$context_file" <<EOF
# Bootstrap Context
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# This file is auto-generated. Do not edit manually.

BOOTSTRAP_SUBSCRIPTION_ID="$sub_id"
BOOTSTRAP_SUBSCRIPTION_NAME="$MANAGEMENT_SUBSCRIPTION_NAME"
EOF
    
    log_info "Bootstrap context saved to: $context_file"
}

# Load bootstrap subscription context from file
load_bootstrap_context() {
    local context_file="${BOOTSTRAP_CONTEXT_FILE}"
    
    if [[ -f "$context_file" ]]; then
        source "$context_file"
        return 0
    else
        return 1
    fi
}

# Ensure we have a valid subscription context
# This function checks if the bootstrap subscription exists and sets it as default
ensure_subscription_context() {
    # First, try to load saved context
    if load_bootstrap_context && [[ -n "${BOOTSTRAP_SUBSCRIPTION_ID:-}" ]]; then
        # Verify the subscription still exists and we have access
        if az account show --subscription "$BOOTSTRAP_SUBSCRIPTION_ID" &> /dev/null 2>&1; then
            az account set --subscription "$BOOTSTRAP_SUBSCRIPTION_ID" &> /dev/null
            return 0
        fi
    fi
    
    # Try to find the management subscription
    local sub_id
    sub_id=$(az account list --query "[?name=='$MANAGEMENT_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$sub_id" ]]; then
        az account set --subscription "$sub_id" &> /dev/null
        save_bootstrap_context "$sub_id"
        return 0
    fi
    
    # No valid subscription context found
    return 1
}

# Check if bootstrap subscription exists
check_bootstrap_subscription() {
    local sub_id
    sub_id=$(az account list --query "[?name=='$MANAGEMENT_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$sub_id" ]]; then
        echo "$sub_id"
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Subscription Lookup Functions
# =============================================================================
# These functions dynamically lookup subscription IDs by name from Azure.

# Lookup management subscription ID (required - fails if not found)
# Usage: MGMT_SUB_ID=$(lookup_management_subscription_id) || exit 1
lookup_management_subscription_id() {
    local sub_id
    sub_id=$(az account list --query "[?name=='$MANAGEMENT_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")
    if [[ -z "$sub_id" ]]; then
        log_error "Management subscription not found: $MANAGEMENT_SUBSCRIPTION_NAME"
        return 1
    fi
    echo "$sub_id"
}

# Lookup hub subscription ID (optional - returns empty if not found)
# The hub (connectivity) subscription is created by the foundation pipeline,
# so it may not exist during initial bootstrap.
# Usage: HUB_SUB_ID=$(lookup_hub_subscription_id)
lookup_hub_subscription_id() {
    az account list --query "[?name=='$CONNECTIVITY_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo ""
}

# =============================================================================
# Variable Group Functions
# =============================================================================
# Helper functions for managing Azure DevOps variable groups.
# These are used by the create-*-variables.sh scripts.

# Check if a variable group exists
variable_group_exists() {
    local group_name="$1"
    
    az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[?name=='${group_name}'].id" \
        -o tsv 2>/dev/null | grep -q .
}

# Get variable group ID by name
get_variable_group_id() {
    local group_name="$1"
    
    az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[?name=='${group_name}'].id | [0]" \
        -o tsv 2>/dev/null
}

# Create a new variable group and return its ID
create_variable_group() {
    local group_name="$1"
    local description="$2"
    
    local group_id
    group_id=$(az pipelines variable-group create \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --name "${group_name}" \
        --description "${description}" \
        --variables dummy=placeholder \
        --authorize true \
        --query 'id' \
        -o tsv 2>/dev/null)
    
    if [[ -z "$group_id" ]]; then
        log_error "Failed to create variable group: ${group_name}"
        return 1
    fi
    
    echo "$group_id"
}

# Update a variable in a variable group (creates if doesn't exist)
update_variable() {
    local group_id="$1"
    local var_name="$2"
    local var_value="$3"
    local is_secret="${4:-false}"
    
    # Try to update first, if fails then create
    # Use || true to prevent set -e from exiting on expected failures
    local update_result=0
    az pipelines variable-group variable update \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --group-id "${group_id}" \
        --name "${var_name}" \
        --value "${var_value}" \
        --secret "${is_secret}" \
        -o none 2>/dev/null || update_result=$?
    
    if [[ $update_result -ne 0 ]]; then
        # Variable doesn't exist, create it
        if ! az pipelines variable-group variable create \
            --org "${ADO_ORGANIZATION_URL}" \
            --project "${ADO_PROJECT_NAME}" \
            --group-id "${group_id}" \
            --name "${var_name}" \
            --value "${var_value}" \
            --secret "${is_secret}" \
            -o none; then
            log_error "Failed to create variable '${var_name}' in group ${group_id}"
            return 1
        fi
    fi
}

# Delete a variable from a variable group
delete_variable() {
    local group_id="$1"
    local var_name="$2"
    
    az pipelines variable-group variable delete \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --group-id "${group_id}" \
        --name "${var_name}" \
        --yes \
        -o none 2>/dev/null || true
}

# Get or create a variable group (returns the group ID)
get_or_create_variable_group() {
    local group_name="$1"
    local description="$2"
    
    local group_id=""
    
    if variable_group_exists "$group_name"; then
        log_info "Variable group '${group_name}' already exists, updating..."
        group_id=$(get_variable_group_id "$group_name")
    else
        log_info "Creating new variable group '${group_name}'..."
        group_id=$(create_variable_group "$group_name" "$description")
        if [[ -n "$group_id" ]]; then
            log_success "Created variable group with ID: ${group_id}"
        fi
    fi
    
    echo "$group_id"
}

# =============================================================================
# Environment Functions
# =============================================================================
# Helper functions for managing Azure DevOps environments.
# These are used by the create-environments.sh script.
#
# Required PAT Permissions:
#   - Environment: Read & Manage (under Pipelines in PAT creation UI)

# Check if an environment exists
environment_exists() {
    local env_name="$1"
    
    # Use REST API to list environments
    # API format: GET https://dev.azure.com/{organization}/{project}/_apis/distributedtask/environments
    local error_output
    local json_output
    error_output=$(az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters "project=${ADO_PROJECT_NAME}" \
        --org "${ADO_ORGANIZATION_URL}" \
        --api-version "7.0" \
        --http-method GET \
        -o json 2>&1)
    local exit_code=$?
    
    # If command failed, check if it's a permission issue
    if [[ $exit_code -ne 0 ]]; then
        if echo "$error_output" | grep -qi "authentication\|unauthorized\|forbidden\|access denied"; then
            log_warn "Permission error checking for environment '${env_name}'"
            log_warn "This may indicate missing PAT permissions (Environment: Read & Manage)"
        fi
        return 1
    fi
    
    # Check if environment name exists in the JSON response
    if echo "$error_output" | jq -e --arg name "$env_name" '.value[] | select(.name == $name)' > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get environment ID by name
get_environment_id() {
    local env_name="$1"
    
    local json_output
    json_output=$(az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters "project=${ADO_PROJECT_NAME}" \
        --org "${ADO_ORGANIZATION_URL}" \
        --api-version "7.0" \
        --http-method GET \
        -o json 2>/dev/null)
    
    if [[ -n "$json_output" ]]; then
        echo "$json_output" | jq -r --arg name "$env_name" '.value[] | select(.name == $name) | .id' 2>/dev/null
    fi
}

# Create a new environment and return its ID
create_environment() {
    local env_name="$1"
    
    # Create JSON payload for the REST API
    local payload
    payload=$(jq -n --arg name "$env_name" '{name: $name, description: "Created via az-build scripts"}')
    
    # Create a temporary file for the payload
    local payload_file
    payload_file=$(mktemp)
    echo "$payload" > "$payload_file"
    
    # Capture both stdout and stderr
    local output
    local error_output
    local exit_code
    
    # Create a temporary file for stderr
    local error_file
    error_file=$(mktemp)
    
    # Use REST API to create environment
    # API format: POST https://dev.azure.com/{organization}/{project}/_apis/distributedtask/environments
    output=$(az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters "project=${ADO_PROJECT_NAME}" \
        --org "${ADO_ORGANIZATION_URL}" \
        --api-version "7.0" \
        --http-method POST \
        --in-file "$payload_file" \
        -o json 2>"$error_file")
    exit_code=$?
    
    # Clean up payload file
    rm -f "$payload_file"
    
    # Read error output if command failed
    if [[ $exit_code -ne 0 ]] || [[ -z "$output" ]]; then
        error_output=$(cat "$error_file" 2>/dev/null || echo "")
        rm -f "$error_file"
        
        log_error "Failed to create environment: ${env_name}"
        
        # Provide helpful error messages based on common issues
        if echo "$error_output" | grep -qi "authentication\|unauthorized\|forbidden\|access denied\|401\|403"; then
            echo ""
            log_error "Authentication or permission error detected."
            echo ""
            echo "  This usually means your PAT token is missing required permissions."
            echo ""
            echo "  Required PAT permissions:"
            echo "    - Environment: Read & Manage (under Pipelines)"
            echo "    - Project and Team: Read (under Project)"
            echo ""
            echo "  To fix:"
            echo "    1. Go to: ${ADO_ORGANIZATION_URL}/_usersSettings/tokens"
            echo "    2. Create/edit your PAT"
            echo "    3. Expand 'Pipelines' section"
            echo "    4. Check 'Environment → Read & Manage'"
            echo "    5. Update ADO_PAT_TOKEN in config.sh"
            echo ""
        elif echo "$error_output" | grep -qi "not found\|does not exist\|404"; then
            echo ""
            log_error "Project or organization not found."
            echo ""
            echo "  Verify in config.sh:"
            echo "    - ADO_ORGANIZATION_URL: ${ADO_ORGANIZATION_URL}"
            echo "    - ADO_PROJECT_NAME: ${ADO_PROJECT_NAME}"
            echo ""
        elif echo "$error_output" | grep -qi "already exists\|duplicate\|409"; then
            # This shouldn't happen if we check first, but handle it gracefully
            log_warn "Environment may already exist (checking...)"
            # Try to get the ID of the existing environment
            local existing_id
            existing_id=$(get_environment_id "$env_name")
            if [[ -n "$existing_id" ]]; then
                echo "$existing_id"
                return 0
            fi
        fi
        
        # Always show the raw error if available
        if [[ -n "$error_output" ]]; then
            echo ""
            log_info "Azure CLI error details:"
            # Try to extract error message from JSON if it's JSON
            if echo "$error_output" | jq -e '.message' > /dev/null 2>&1; then
                echo "$error_output" | jq -r '.message' | sed 's/^/  /'
            else
                echo "$error_output" | sed 's/^/  /'
            fi
            echo ""
        fi
        
        return 1
    fi
    
    rm -f "$error_file"
    
    # Extract environment ID from JSON response
    local env_id
    env_id=$(echo "$output" | jq -r '.id' 2>/dev/null)
    
    if [[ -z "$env_id" ]] || [[ "$env_id" == "null" ]]; then
        log_error "Created environment but could not retrieve ID: ${env_name}"
        log_info "Response was: ${output}"
        return 1
    fi
    
    echo "$env_id"
    return 0
}

# Get or create an environment (returns the environment ID)
get_or_create_environment() {
    local env_name="$1"
    
    local env_id=""
    
    if environment_exists "$env_name"; then
        log_info "Environment '${env_name}' already exists, skipping..."
        env_id=$(get_environment_id "$env_name")
    else
        log_info "Creating new environment '${env_name}'..."
        env_id=$(create_environment "$env_name")
        if [[ -n "$env_id" ]]; then
            log_success "Created environment '${env_name}' with ID: ${env_id}"
        fi
    fi
    
    echo "$env_id"
}

# =============================================================================
# Export for child scripts
# =============================================================================
export -f log_info log_success log_warn log_error log_step validate_config
export -f save_bootstrap_context load_bootstrap_context ensure_subscription_context check_bootstrap_subscription
export -f lookup_management_subscription_id lookup_hub_subscription_id
export -f variable_group_exists get_variable_group_id create_variable_group update_variable delete_variable get_or_create_variable_group
export -f environment_exists get_environment_id create_environment get_or_create_environment
export BOOTSTRAP_CONTEXT_FILE

