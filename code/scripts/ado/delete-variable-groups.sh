#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Delete Variable Groups
# =============================================================================
# This script deletes variable groups. Use with caution!
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
# Functions
# =============================================================================

# Get variable group ID by name
get_variable_group_id() {
    local group_name="$1"
    
    az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[?name=='${group_name}'].id | [0]" \
        -o tsv 2>/dev/null
}

# Delete a variable group
delete_variable_group() {
    local group_name="$1"
    
    log_step "Deleting variable group: ${group_name}"
    
    local group_id
    group_id=$(get_variable_group_id "$group_name")
    
    if [[ -z "$group_id" ]]; then
        log_warn "Variable group '${group_name}' not found, skipping"
        return 0
    fi
    
    az pipelines variable-group delete \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --group-id "$group_id" \
        --yes \
        -o none
    
    log_success "Deleted variable group '${group_name}' (ID: ${group_id})"
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [GROUP_NAME...]"
    echo ""
    echo "Delete Azure DevOps variable groups."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -a, --all           Delete all managed variable groups (common-variables)"
    echo "  -f, --force         Skip confirmation prompt"
    echo ""
    echo "Arguments:"
    echo "  GROUP_NAME          Name(s) of variable group(s) to delete"
    echo ""
    echo "Examples:"
    echo "  $0 common-variables              # Delete specific group"
    echo "  $0 --all                         # Delete all managed groups"
    echo "  $0 --all --force                 # Delete all without confirmation"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local delete_all=false
    local force=false
    local groups_to_delete=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -a|--all)
                delete_all=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                groups_to_delete+=("$1")
                shift
                ;;
        esac
    done
    
    echo ""
    echo "============================================================================="
    echo "  Azure DevOps Variable Groups - Delete"
    echo "============================================================================="
    echo ""
    
    # Determine which groups to delete
    if [[ "$delete_all" == "true" ]]; then
        groups_to_delete=("common-variables")
    fi
    
    if [[ ${#groups_to_delete[@]} -eq 0 ]]; then
        log_error "No variable groups specified"
        echo ""
        show_usage
        exit 1
    fi
    
    # Confirmation
    if [[ "$force" != "true" ]]; then
        log_warn "This will delete the following variable groups:"
        for group in "${groups_to_delete[@]}"; do
            echo "  - ${group}"
        done
        echo ""
        read -p "Are you sure you want to continue? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    # Delete groups
    for group in "${groups_to_delete[@]}"; do
        delete_variable_group "$group"
    done
    
    echo ""
    log_success "Done!"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
