#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update All Variable Groups
# =============================================================================
# This script orchestrates the creation/update of all variable groups required
# by the infrastructure deployment pipelines. It calls individual scripts for
# each variable group in sequence.
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
# Variable Group Scripts
# =============================================================================
# Add new variable group scripts here in the order they should be executed.
# Each script should handle creating/updating a single variable group.

VARIABLE_GROUP_SCRIPTS=(
    "create-common-variables.sh"
    "create-mg-hierarchy-variables.sh"
    "create-monitoring-variables.sh"
    "create-governance-variables.sh"
    "create-hub-variables.sh"
    # Add additional variable group scripts here as needed:
    # "create-spoke-variables.sh"
)

# =============================================================================
# Functions
# =============================================================================

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update Azure DevOps variable groups for infrastructure pipelines."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -l, --list          List existing variable groups"
    echo "  -v, --verbose       Enable verbose output"
    echo ""
    echo "Variable groups managed by this script:"
    for script in "${VARIABLE_GROUP_SCRIPTS[@]}"; do
        echo "  - ${script%.sh}"
    done
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed with azure-devops extension"
    echo "  - config.sh configured with required variables"
    echo "  - Valid Azure DevOps PAT token"
    echo ""
    echo "Run './check-prerequisites.sh' to verify all prerequisites."
}

# List existing variable groups
list_variable_groups() {
    log_info "Listing variable groups in project '${ADO_PROJECT_NAME}'..."
    echo ""
    
    az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[].{Name:name, ID:id, Description:description}" \
        -o table
}

# Run a variable group script
run_script() {
    local script_name="$1"
    local dry_run="$2"
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: ${script_path}"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log_warn "Script not executable, running with bash: ${script_name}"
        if [[ "$dry_run" == "true" ]]; then
            bash "$script_path" --dry-run
        else
            bash "$script_path"
        fi
    else
        if [[ "$dry_run" == "true" ]]; then
            "$script_path" --dry-run
        else
            "$script_path"
        fi
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
    local list_mode=false
    local verbose=false
    
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
            -l|--list)
                list_mode=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo ""
    echo "============================================================================="
    echo "  Azure DevOps Variable Groups - Create/Update"
    echo "============================================================================="
    echo ""
    
    # Verify prerequisites
    log_step "Verifying prerequisites..."
    if ! "${SCRIPT_DIR}/check-prerequisites.sh" > /dev/null 2>&1; then
        log_error "Prerequisites check failed. Run './check-prerequisites.sh' for details."
        exit 1
    fi
    log_success "Prerequisites verified"
    echo ""
    
    # List mode
    if [[ "$list_mode" == "true" ]]; then
        list_variable_groups
        exit 0
    fi
    
    # Display configuration
    log_info "Organization: ${ADO_ORGANIZATION_URL}"
    log_info "Project: ${ADO_PROJECT_NAME}"
    echo ""
    
    if [[ "$dry_run_mode" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Run each variable group script in sequence
    local script_count=${#VARIABLE_GROUP_SCRIPTS[@]}
    local current=0
    
    for script in "${VARIABLE_GROUP_SCRIPTS[@]}"; do
        ((current++))
        echo ""
        echo "-----------------------------------------------------------------------------"
        log_step "Running script ${current}/${script_count}: ${script}"
        echo "-----------------------------------------------------------------------------"
        
        if ! run_script "$script" "$dry_run_mode"; then
            log_error "Failed to run ${script}"
            exit 1
        fi
    done
    
    echo ""
    echo "============================================================================="
    log_success "All variable groups created/updated successfully!"
    echo "============================================================================="
    echo ""
    log_info "Next steps:"
    echo "  1. Verify the variable groups in Azure DevOps:"
    echo "     ${ADO_ORGANIZATION_URL}/${ADO_PROJECT_NAME}/_library?itemType=VariableGroups"
    echo ""
    echo "  2. Ensure your Azure service connection '${AZURE_SERVICE_CONNECTION_NAME:-azure-infra-connection}' exists"
    echo ""
    echo "  3. Run your pipelines!"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
