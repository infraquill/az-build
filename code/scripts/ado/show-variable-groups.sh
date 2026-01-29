#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Show Details
# =============================================================================
# This script displays detailed information about variable groups.
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

# Show details of a variable group
show_variable_group_details() {
    local group_name="$1"
    
    local group_id
    group_id=$(get_variable_group_id "$group_name")
    
    if [[ -z "$group_id" ]]; then
        log_warn "Variable group '${group_name}' not found"
        return 1
    fi
    
    echo ""
    log_info "Variable Group: ${group_name} (ID: ${group_id})"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    az pipelines variable-group show \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --group-id "$group_id" \
        --query "variables" \
        -o json | jq -r 'to_entries | .[] | "  \(.key): \(if .value.isSecret then "***SECRET***" else .value.value end)"'
    
    echo ""
}

# List all variable groups
list_all_variable_groups() {
    log_info "All variable groups in project '${ADO_PROJECT_NAME}':"
    echo ""
    
    az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[].{Name:name, ID:id, Description:description, Variables:variables | keys(@) | length(@)}" \
        -o table
}

# Show all details
show_all() {
    list_all_variable_groups
    
    echo ""
    echo "============================================================================="
    echo "  Variable Group Details"
    echo "============================================================================="
    
    # Get all group names
    local groups
    groups=$(az pipelines variable-group list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[].name" \
        -o tsv 2>/dev/null)
    
    if [[ -z "$groups" ]]; then
        log_warn "No variable groups found"
        return 0
    fi
    
    while IFS= read -r group_name; do
        if [[ -n "$group_name" ]]; then
            show_variable_group_details "$group_name"
        fi
    done <<< "$groups"
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [GROUP_NAME]"
    echo ""
    echo "Display Azure DevOps variable group details."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -a, --all           Show all variable groups and their variables"
    echo "  -l, --list          List variable groups (without details)"
    echo ""
    echo "Arguments:"
    echo "  GROUP_NAME          Name of specific variable group to show"
    echo ""
    echo "Examples:"
    echo "  $0 --list                        # List all groups"
    echo "  $0 --all                         # Show all groups with details"
    echo "  $0 common-variables              # Show specific group details"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local show_all_mode=false
    local list_mode=false
    local group_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -a|--all)
                show_all_mode=true
                shift
                ;;
            -l|--list)
                list_mode=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                group_name="$1"
                shift
                ;;
        esac
    done
    
    echo ""
    echo "============================================================================="
    echo "  Azure DevOps Variable Groups - Details"
    echo "============================================================================="
    echo ""
    log_info "Organization: ${ADO_ORGANIZATION_URL}"
    log_info "Project: ${ADO_PROJECT_NAME}"
    
    if [[ "$list_mode" == "true" ]]; then
        echo ""
        list_all_variable_groups
    elif [[ "$show_all_mode" == "true" ]]; then
        show_all
    elif [[ -n "$group_name" ]]; then
        show_variable_group_details "$group_name"
    else
        # Default: show all
        show_all
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
