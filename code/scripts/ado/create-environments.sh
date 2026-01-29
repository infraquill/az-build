#!/bin/bash
# =============================================================================
# Azure DevOps Environments - Create/Update Environments
# =============================================================================
# This script creates Azure DevOps environments used by deployment pipelines.
# Environments align with the environment parameter values used across pipelines.
#
# Prerequisites:
#   - Azure CLI with azure-devops extension
#   - config.sh with ADO_PAT_TOKEN set
#
# Required PAT Permissions:
#   - Environment: Read & Manage (under Pipelines in PAT creation UI)
#   - Project and Team: Read (under Project in PAT creation UI)
#
# Usage:
#   bash create-environments.sh           # Create all environments
#   bash create-environments.sh --dry-run # Preview changes
#   bash create-environments.sh --list    # List existing environments
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

# Environments configuration (from config.sh)
# If not set in config.sh, use default environments
if [[ -z "${ENVIRONMENTS[*]:-}" ]]; then
    ENVIRONMENTS=("nonprod" "dev" "test" "uat" "staging" "prod" "live")
fi

# =============================================================================
# Functions
# =============================================================================

# Test Azure DevOps connection and permissions
test_ado_permissions() {
    log_step "Testing Azure DevOps connection and permissions..."
    
    # Test basic connection by listing environments using REST API
    local error_output
    error_output=$(az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters "project=${ADO_PROJECT_NAME}" \
        --org "${ADO_ORGANIZATION_URL}" \
        --api-version "7.0" \
        --http-method GET \
        -o json 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to connect to Azure DevOps or list environments"
        echo ""
        
        if echo "$error_output" | grep -qi "authentication\|unauthorized\|forbidden\|access denied\|401\|403"; then
            log_error "Permission error detected!"
            echo ""
            echo "  Your PAT token is missing required permissions."
            echo ""
            echo "  Required permissions:"
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
        else
            log_info "Error details:"
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
    
    log_success "Connection and permissions verified"
    return 0
}

# Create all environments from the ENVIRONMENTS array
create_all_environments() {
    echo ""
    log_info "Creating Azure DevOps environments..."
    log_info "Environments to create: ${ENVIRONMENTS[*]}"
    echo ""
    
    # Test permissions first
    if ! test_ado_permissions; then
        log_error "Permission check failed. Cannot proceed with environment creation."
        return 1
    fi
    echo ""
    
    local created=0
    local skipped=0
    local failed=0
    
    for env_name in "${ENVIRONMENTS[@]}"; do
        if environment_exists "$env_name"; then
            log_info "Environment '${env_name}' already exists, skipping..."
            ((skipped++))
        else
            log_info "Creating environment '${env_name}'..."
            if env_id=$(create_environment "$env_name"); then
                log_success "Created environment '${env_name}' with ID: ${env_id}"
                ((created++))
            else
                log_error "Failed to create environment '${env_name}'"
                ((failed++))
                echo ""
            fi
        fi
    done
    
    echo ""
    log_info "Summary:"
    echo "  - Created: ${created}"
    echo "  - Already existed: ${skipped}"
    if [[ $failed -gt 0 ]]; then
        log_error "  - Failed: ${failed}"
        echo ""
        log_error "Some environments failed to create."
        echo ""
        echo "  Common causes:"
        echo "    1. Missing PAT permissions: Environment → Read & Manage"
        echo "    2. Invalid organization URL or project name"
        echo "    3. PAT token expired or revoked"
        echo ""
        echo "  Check the error messages above for specific details."
        echo "  Verify your PAT at: ${ADO_ORGANIZATION_URL}/_usersSettings/tokens"
        echo ""
        return 1
    fi
    
    log_success "All environments processed successfully"
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create the following environments:"
    for env_name in "${ENVIRONMENTS[@]}"; do
        if environment_exists "$env_name"; then
            echo "  - ${env_name} (already exists, would skip)"
        else
            echo "  - ${env_name} (would create)"
        fi
    done
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
}

# List existing environments
list_environments() {
    log_info "Listing environments in project '${ADO_PROJECT_NAME}'..."
    echo ""
    
    local json_output
    json_output=$(az devops invoke \
        --area distributedtask \
        --resource environments \
        --route-parameters "project=${ADO_PROJECT_NAME}" \
        --org "${ADO_ORGANIZATION_URL}" \
        --api-version "7.0" \
        --http-method GET \
        -o json 2>&1)
    
    if [[ $? -eq 0 ]] && echo "$json_output" | jq -e '.value' > /dev/null 2>&1; then
        echo "$json_output" | jq -r '.value[] | "\(.name)\t\(.id)"' | column -t -s $'\t' -N "Name,ID"
    else
        log_error "Failed to list environments"
        echo "$json_output" | jq -r '.message' 2>/dev/null || echo "$json_output"
    fi
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create Azure DevOps environments used by deployment pipelines."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -l, --list          List existing environments"
    echo ""
    echo "Environments to be created (from config.sh):"
    for env_name in "${ENVIRONMENTS[@]}"; do
        echo "  - ${env_name}"
    done
    echo ""
    echo "This script is typically called by setup-ado.sh"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
    local list_mode=false
    
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
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # List mode
    if [[ "$list_mode" == "true" ]]; then
        list_environments
        exit 0
    fi
    
    # Dry run mode
    if [[ "$dry_run_mode" == "true" ]]; then
        dry_run
        exit 0
    fi
    
    # Create all environments
    create_all_environments
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
