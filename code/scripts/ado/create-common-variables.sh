#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update Common Variables
# =============================================================================
# This script creates or updates the 'common-variables' variable group
# containing shared variables used across all infrastructure pipelines.
# =============================================================================

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config.sh"

# Set ADO PAT for authentication
export AZURE_DEVOPS_EXT_PAT="${ADO_PAT_TOKEN}"

# =============================================================================
# Configuration
# =============================================================================

GROUP_NAME="common-variables"
GROUP_DESCRIPTION="Common variables shared across all infrastructure deployment pipelines"

# Default values (can be overridden in config.sh)
AZURE_SERVICE_CONNECTION_NAME="${AZURE_SERVICE_CONNECTION_NAME:-azure-infra-connection}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-canadacentral}"
DEFAULT_LOCATION_CODE="${DEFAULT_LOCATION_CODE:-cac}"
DEFAULT_OWNER="${DEFAULT_OWNER:-}"
MANAGED_BY="${MANAGED_BY:-Bicep}"
DEFAULT_DENY_SETTINGS_MODE="${DEFAULT_DENY_SETTINGS_MODE:-denyWriteAndDelete}"
DEFAULT_ACTION_ON_UNMANAGE="${DEFAULT_ACTION_ON_UNMANAGE:-detachAll}"

# Required variables (must be set in config.sh)
AAD_TENANT_ID="${AAD_TENANT_ID:-}"

# Billing configuration (for subscription vending)
# Either INVOICE_SECTION_ID (MCA) or ENROLLMENT_ACCOUNT_ID (EA) should be provided, not both
BILLING_ACCOUNT_ID="${BILLING_ACCOUNT_ID:-}"
INVOICE_SECTION_ID="${INVOICE_SECTION_ID:-}"
ENROLLMENT_ACCOUNT_ID="${ENROLLMENT_ACCOUNT_ID:-}"

# Environments configuration (from config.sh)
# Convert ENVIRONMENTS array to comma-separated string for variable group storage
# This enables runtime validation in pipelines against the authoritative list
if [[ -z "${ENVIRONMENTS[*]:-}" ]]; then
    # Default environments if not set in config.sh
    ENVIRONMENTS=("nonprod" "dev" "test" "uat" "staging" "prod" "live")
fi
ENVIRONMENTS_CSV=$(IFS=','; echo "${ENVIRONMENTS[*]}")

# Validate required variables
if [[ -z "${AAD_TENANT_ID}" ]]; then
    log_error "AAD_TENANT_ID is required but not set in config.sh"
    exit 1
fi

# =============================================================================
# Functions
# =============================================================================

# Set a variable and log it
set_variable() {
    local group_id="$1"
    local var_name="$2"
    local var_value="$3"
    log_info "  Setting ${var_name}..."
    update_variable "$group_id" "$var_name" "$var_value" "false"
}

# Create or update the common-variables group
create_common_variables_group() {
    echo ""
    log_info "Processing variable group: ${GROUP_NAME}"
    log_info "Description: ${GROUP_DESCRIPTION}"
    echo ""
    
    local group_id
    group_id=$(get_or_create_variable_group "$GROUP_NAME" "$GROUP_DESCRIPTION")
    
    if [[ -z "$group_id" ]]; then
        log_error "Failed to get or create variable group"
        return 1
    fi
    
    # Update/Create all variables
    log_step "Setting variables..."
    
    set_variable "$group_id" "azureServiceConnection" "${AZURE_SERVICE_CONNECTION_NAME}"
    set_variable "$group_id" "deploymentLocation" "${DEPLOYMENT_LOCATION}"
    set_variable "$group_id" "azureTenantId" "${AAD_TENANT_ID}"
    set_variable "$group_id" "locationCode" "${DEFAULT_LOCATION_CODE}"
    set_variable "$group_id" "defaultOwner" "${DEFAULT_OWNER}"
    set_variable "$group_id" "managedBy" "${MANAGED_BY}"
    set_variable "$group_id" "denySettingsMode" "${DEFAULT_DENY_SETTINGS_MODE}"
    set_variable "$group_id" "actionOnUnmanage" "${DEFAULT_ACTION_ON_UNMANAGE}"
    set_variable "$group_id" "billingAccountId" "${BILLING_ACCOUNT_ID}"
    set_variable "$group_id" "billingProfileId" "${BILLING_PROFILE_ID}"
    set_variable "$group_id" "invoiceSectionId" "${INVOICE_SECTION_ID}"
    set_variable "$group_id" "enrollmentAccountId" "${ENROLLMENT_ACCOUNT_ID}"
    set_variable "$group_id" "environments" "${ENVIRONMENTS_CSV}"
    
    # Remove the dummy placeholder variable if it exists
    delete_variable "$group_id" "dummy"
    
    log_success "Variable group '${GROUP_NAME}' configured successfully"
    
    # Display the variables
    echo ""
    log_info "Variables in '${GROUP_NAME}':"
    echo "  - azureServiceConnection: ${AZURE_SERVICE_CONNECTION_NAME}"
    echo "  - deploymentLocation: ${DEPLOYMENT_LOCATION}"
    echo "  - azureTenantId: ${AAD_TENANT_ID}"
    echo "  - locationCode: ${DEFAULT_LOCATION_CODE}"
    echo "  - defaultOwner: ${DEFAULT_OWNER}"
    echo "  - managedBy: ${MANAGED_BY}"
    echo "  - denySettingsMode: ${DEFAULT_DENY_SETTINGS_MODE}"
    echo "  - actionOnUnmanage: ${DEFAULT_ACTION_ON_UNMANAGE}"
    echo "  - billingAccountId: ${BILLING_ACCOUNT_ID}"
    echo "  - billingProfileId: ${BILLING_PROFILE_ID}"
    echo "  - invoiceSectionId: ${INVOICE_SECTION_ID}"
    echo "  - enrollmentAccountId: ${ENROLLMENT_ACCOUNT_ID}"
    echo "  - environments: ${ENVIRONMENTS_CSV}"
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create/update variable group: ${GROUP_NAME}"
    echo ""
    log_info "Variables that would be set:"
    echo "  - azureServiceConnection: ${AZURE_SERVICE_CONNECTION_NAME}"
    echo "  - deploymentLocation: ${DEPLOYMENT_LOCATION}"
    echo "  - azureTenantId: ${AAD_TENANT_ID}"
    echo "  - locationCode: ${DEFAULT_LOCATION_CODE}"
    echo "  - defaultOwner: ${DEFAULT_OWNER}"
    echo "  - managedBy: ${MANAGED_BY}"
    echo "  - denySettingsMode: ${DEFAULT_DENY_SETTINGS_MODE}"
    echo "  - actionOnUnmanage: ${DEFAULT_ACTION_ON_UNMANAGE}"
    echo "  - billingAccountId: ${BILLING_ACCOUNT_ID}"
    echo "  - billingProfileId: ${BILLING_PROFILE_ID}"
    echo "  - invoiceSectionId: ${INVOICE_SECTION_ID}"
    echo "  - enrollmentAccountId: ${ENROLLMENT_ACCOUNT_ID}"
    echo "  - environments: ${ENVIRONMENTS_CSV}"
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update the 'common-variables' Azure DevOps variable group."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo ""
    echo "This script is typically called by create-variable-groups.sh"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                dry_run_mode=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Dry run mode
    if [[ "$dry_run_mode" == "true" ]]; then
        dry_run
        exit 0
    fi
    
    # Create/update the variable group
    create_common_variables_group
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
