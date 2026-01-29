#!/bin/bash
# =============================================================================
# Azure DevOps Setup - Complete ADO Configuration
# =============================================================================
# This script orchestrates the complete Azure DevOps setup by:
#   1. Creating the Platform Admin service principal (via create-platform-admin.sh)
#   2. Creating/updating all variable groups (via create-variable-groups.sh)
#   3. Creating all deployment environments (via create-environments.sh)
#
# This provides a single entry point for complete ADO setup.
#
# Prerequisites:
#   - Azure CLI with azure-devops extension
#   - config.sh with ADO_PAT_TOKEN set
#
# Required PAT Permissions:
#   - Variable Groups: Read & Manage (under Pipelines in PAT creation UI)
#   - Environment: Read & Manage (under Pipelines in PAT creation UI)
#   - Project and Team: Read (under Project in PAT creation UI)
#
# Usage:
#   bash setup-ado.sh           # Run complete setup
#   bash setup-ado.sh --dry-run # Preview changes without making them
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
# Setup Scripts
# =============================================================================
# Scripts to run in order for complete ADO setup

SETUP_SCRIPTS=(
    "create-platform-admin.sh"
    "create-variable-groups.sh"
    "create-environments.sh"
)

# =============================================================================
# Functions
# =============================================================================

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Complete Azure DevOps setup for infrastructure pipelines."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -v, --verbose       Enable verbose output"
    echo ""
    echo "This script runs the following in sequence:"
    for script in "${SETUP_SCRIPTS[@]}"; do
        echo "  1. ${script}"
    done
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed with azure-devops extension"
    echo "  - config.sh configured with required variables"
    echo "  - Valid Azure DevOps PAT token with required permissions"
    echo ""
    echo "Run 'bash check-prerequisites.sh' to verify all prerequisites."
}

# Run a setup script
run_script() {
    local script_name="$1"
    local dry_run="$2"
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: ${script_path}"
        return 1
    fi
    
    # Scripts that don't support --dry-run mode
    local scripts_without_dry_run=("create-platform-admin.sh")
    
    if [[ "$dry_run" == "true" ]]; then
        # Check if script supports dry-run
        local supports_dry_run=true
        for script in "${scripts_without_dry_run[@]}"; do
            if [[ "$script_name" == "$script" ]]; then
                supports_dry_run=false
                break
            fi
        done
        
        if [[ "$supports_dry_run" == "false" ]]; then
            log_warn "Script ${script_name} does not support --dry-run mode"
            log_info "Running script normally (it is idempotent and checks for existing resources)"
            bash "$script_path"
        else
            bash "$script_path" --dry-run
        fi
    else
        bash "$script_path"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
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
    echo "  Azure DevOps Setup - Complete Configuration"
    echo "============================================================================="
    echo ""
    
    # Verify prerequisites
    log_step "Verifying prerequisites..."
    if ! bash "${SCRIPT_DIR}/check-prerequisites.sh" > /dev/null 2>&1; then
        log_error "Prerequisites check failed. Run 'bash check-prerequisites.sh' for details."
        exit 1
    fi
    log_success "Prerequisites verified"
    echo ""
    
    # Display configuration
    log_info "Organization: ${ADO_ORGANIZATION_URL}"
    log_info "Project: ${ADO_PROJECT_NAME}"
    echo ""
    
    if [[ "$dry_run_mode" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Run each setup script in sequence
    local script_count=${#SETUP_SCRIPTS[@]}
    local current=0
    
    for script in "${SETUP_SCRIPTS[@]}"; do
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
    log_success "Azure DevOps setup completed successfully!"
    echo "============================================================================="
    echo ""
    log_info "What was configured:"
    echo "  - Platform Admin service principal for bootstrap operations"
    echo "  - Variable groups for pipeline configuration"
    echo "  - Deployment environments for pipeline stages"
    echo ""
    log_info "Next steps:"
    echo "  1. Verify the configuration in Azure DevOps:"
    echo "     - Variable Groups: ${ADO_ORGANIZATION_URL}/${ADO_PROJECT_NAME}/_library?itemType=VariableGroups"
    echo "     - Environments: ${ADO_ORGANIZATION_URL}/${ADO_PROJECT_NAME}/_environments"
    echo ""
    echo "  2. Ensure your Azure service connection '${AZURE_SERVICE_CONNECTION_NAME:-azure-infra-connection}' exists"
    echo ""
    echo "  3. Run your pipelines!"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
