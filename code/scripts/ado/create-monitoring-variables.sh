#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update Monitoring Variables
# =============================================================================
# This script creates or updates the 'monitoring-variables' variable group
# containing variables used by the monitoring infrastructure pipeline.
#
# Parameter Placement Strategy:
# - This variable group only contains STRING values that may need organization-wide updates
# - Stable configuration (SKU, thresholds, security settings) is in bicepparam files
# - ADO variable groups only support strings, not complex data structures
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

GROUP_NAME="monitoring-variables"
GROUP_DESCRIPTION="Variables for monitoring infrastructure deployment pipeline. Contains string values only (subscription ID, emails, SMS numbers). Stable configuration is in bicepparam files."

# Default values (can be overridden in config.sh)
# Subscription ID for monitoring resources
MONITORING_SUBSCRIPTION_ID="${MONITORING_SUBSCRIPTION_ID:-}"

# Action Group notification recipients
# These are string values that may need organization-wide updates without code changes
ACTION_GROUP_EMAILS="${ACTION_GROUP_EMAILS:-}"
ACTION_GROUP_SMS_NUMBERS="${ACTION_GROUP_SMS_NUMBERS:-}"

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

# Create or update the monitoring-variables group
create_monitoring_variables_group() {
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
    
    # Subscription ID for monitoring resources
    set_variable "$group_id" "monitoringSubscriptionId" "${MONITORING_SUBSCRIPTION_ID}"
    
    # Action Group notification recipients (string values only)
    # These are passed to the pipeline and converted to arrays for Bicep deployment
    set_variable "$group_id" "actionGroupEmails" "${ACTION_GROUP_EMAILS}"
    set_variable "$group_id" "actionGroupSmsNumbers" "${ACTION_GROUP_SMS_NUMBERS}"
    
    # Remove the dummy placeholder variable if it exists
    delete_variable "$group_id" "dummy"
    
    # Remove deprecated variables if they exist (now in bicepparam or replaced)
    delete_variable "$group_id" "dataRetention" 2>/dev/null || true
    delete_variable "$group_id" "monitoringSubscriptionAlias" 2>/dev/null || true
    
    log_success "Variable group '${GROUP_NAME}' configured successfully"
    
    # Display the variables
    echo ""
    log_info "Variables in '${GROUP_NAME}':"
    if [[ -z "${MONITORING_SUBSCRIPTION_ID}" ]]; then
        echo "  - monitoringSubscriptionId: (empty - set after subscription is created)"
    else
        echo "  - monitoringSubscriptionId: ${MONITORING_SUBSCRIPTION_ID}"
    fi
    if [[ -z "${ACTION_GROUP_EMAILS}" ]]; then
        echo "  - actionGroupEmails: (empty - configure for alert notifications)"
    else
        echo "  - actionGroupEmails: ${ACTION_GROUP_EMAILS}"
    fi
    if [[ -z "${ACTION_GROUP_SMS_NUMBERS}" ]]; then
        echo "  - actionGroupSmsNumbers: (empty - optional)"
    else
        echo "  - actionGroupSmsNumbers: ${ACTION_GROUP_SMS_NUMBERS}"
    fi
    
    echo ""
    log_info "Note: Stable configuration (SKU, thresholds, security settings) is defined in bicepparam files."
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create/update variable group: ${GROUP_NAME}"
    echo ""
    log_info "Variables that would be set:"
    if [[ -z "${MONITORING_SUBSCRIPTION_ID}" ]]; then
        echo "  - monitoringSubscriptionId: (empty - set after subscription is created)"
    else
        echo "  - monitoringSubscriptionId: ${MONITORING_SUBSCRIPTION_ID}"
    fi
    if [[ -z "${ACTION_GROUP_EMAILS}" ]]; then
        echo "  - actionGroupEmails: (empty - configure for alert notifications)"
    else
        echo "  - actionGroupEmails: ${ACTION_GROUP_EMAILS}"
    fi
    if [[ -z "${ACTION_GROUP_SMS_NUMBERS}" ]]; then
        echo "  - actionGroupSmsNumbers: (empty - optional)"
    else
        echo "  - actionGroupSmsNumbers: ${ACTION_GROUP_SMS_NUMBERS}"
    fi
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
    echo ""
    log_info "Note: Stable configuration (SKU, thresholds, security settings) is defined in bicepparam files."
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update the 'monitoring-variables' Azure DevOps variable group."
    echo ""
    echo "This variable group contains STRING values only that may need organization-wide updates:"
    echo "  - monitoringSubscriptionId: The subscription ID for monitoring resources"
    echo "  - actionGroupEmails: Comma-separated email addresses for alert notifications"
    echo "  - actionGroupSmsNumbers: Comma-separated SMS numbers (optional)"
    echo ""
    echo "Note: Stable configuration (SKU, thresholds, security settings) is defined in bicepparam files,"
    echo "not in variable groups. ADO variable groups only support strings."
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
    create_monitoring_variables_group
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
