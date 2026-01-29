#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update MG Hierarchy Variables
# =============================================================================
# This script creates or updates the 'mg-hierarchy-variables' variable group
# containing variables used by the management group hierarchy pipeline.
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

GROUP_NAME="mg-hierarchy-variables"
GROUP_DESCRIPTION="Variables for management group hierarchy deployment pipeline"

# Default values (can be overridden in config.sh)
ORG_NAME="${ORG_NAME:-org}"
ORG_DISPLAY_NAME="${ORG_DISPLAY_NAME:-Organization Name}"

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

# Create or update the mg-hierarchy-variables group
create_mg_hierarchy_variables_group() {
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
    
    set_variable "$group_id" "orgName" "${ORG_NAME}"
    set_variable "$group_id" "orgDisplayName" "${ORG_DISPLAY_NAME}"
    
    # Remove the dummy placeholder variable if it exists
    delete_variable "$group_id" "dummy"
    
    log_success "Variable group '${GROUP_NAME}' configured successfully"
    
    # Display the variables
    echo ""
    log_info "Variables in '${GROUP_NAME}':"
    echo "  - orgName: ${ORG_NAME}"
    echo "  - orgDisplayName: ${ORG_DISPLAY_NAME}"
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create/update variable group: ${GROUP_NAME}"
    echo ""
    log_info "Variables that would be set:"
    echo "  - orgName: ${ORG_NAME}"
    echo "  - orgDisplayName: ${ORG_DISPLAY_NAME}"
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update the 'mg-hierarchy-variables' Azure DevOps variable group."
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
    create_mg_hierarchy_variables_group
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
