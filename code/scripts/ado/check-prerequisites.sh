#!/bin/bash
# =============================================================================
# Azure DevOps Setup - Prerequisites Check
# =============================================================================
# This script checks that all prerequisites are met before running
# the ADO setup scripts (variable groups and environments).
# =============================================================================

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the library for color output
source "${SCRIPT_DIR}/lib.sh"

# =============================================================================
# Prerequisites Check Functions
# =============================================================================

check_azure_cli() {
    log_step "Checking Azure CLI installation..."
    if command -v az &> /dev/null; then
        local version
        version=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "unknown")
        log_success "Azure CLI installed (version: ${version})"
        return 0
    else
        log_error "Azure CLI is not installed"
        echo ""
        echo "  Installation instructions:"
        echo "  - macOS:   brew install azure-cli"
        echo "  - Ubuntu:  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        echo "  - Windows: winget install Microsoft.AzureCLI"
        echo "  - Manual:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        echo ""
        return 1
    fi
}

check_azure_devops_extension() {
    log_step "Checking Azure DevOps CLI extension..."
    if az extension show --name azure-devops &> /dev/null; then
        local version
        version=$(az extension show --name azure-devops --query 'version' -o tsv 2>/dev/null || echo "unknown")
        log_success "Azure DevOps extension installed (version: ${version})"
        return 0
    else
        log_error "Azure DevOps CLI extension is not installed"
        echo ""
        echo "  Installation command:"
        echo "  az extension add --name azure-devops"
        echo ""
        echo "  To update to the latest version:"
        echo "  az extension update --name azure-devops"
        echo ""
        return 1
    fi
}

check_jq() {
    log_step "Checking jq installation..."
    if command -v jq &> /dev/null; then
        local version
        version=$(jq --version 2>/dev/null || echo "unknown")
        log_success "jq installed (version: ${version})"
        return 0
    else
        log_error "jq is not installed"
        echo ""
        echo "  Installation instructions:"
        echo "  - macOS:   brew install jq"
        echo "  - Ubuntu:  sudo apt-get install jq"
        echo "  - Windows: choco install jq"
        echo "  - Manual:  https://stedolan.github.io/jq/download/"
        echo ""
        return 1
    fi
}

check_azure_login() {
    log_step "Checking Azure CLI login status..."
    if az account show &> /dev/null; then
        local account_name
        local tenant_id
        account_name=$(az account show --query 'name' -o tsv 2>/dev/null || echo "unknown")
        tenant_id=$(az account show --query 'tenantId' -o tsv 2>/dev/null || echo "unknown")
        log_success "Logged in to Azure (Account: ${account_name}, Tenant: ${tenant_id})"
        return 0
    else
        log_error "Not logged in to Azure CLI"
        echo ""
        echo "  Login command:"
        echo "  az login"
        echo ""
        echo "  For a specific tenant:"
        echo "  az login --tenant <tenant-id>"
        echo ""
        return 1
    fi
}

check_config_file() {
    log_step "Checking config.sh file..."
    local config_file="${SCRIPT_DIR}/config.sh"
    
    if [[ -f "$config_file" ]]; then
        log_success "config.sh file exists"
        return 0
    else
        log_error "config.sh file not found"
        echo ""
        echo "  Please create config.sh by copying the example:"
        echo "  cp ${SCRIPT_DIR}/config.sh.example ${SCRIPT_DIR}/config.sh"
        echo ""
        echo "  Then edit config.sh with your values."
        echo ""
        return 1
    fi
}

check_config_variables() {
    log_step "Checking required configuration variables..."
    
    local config_file="${SCRIPT_DIR}/config.sh"
    local errors=0
    local warnings=0
    
    # Source the config file
    source "$config_file"
    
    # Required variables for variable group creation
    local required_vars=(
        "AAD_TENANT_ID"
        "ADO_PAT_TOKEN"
        "ADO_ORGANIZATION_URL"
        "ADO_PROJECT_NAME"
    )
    
    # Optional but recommended variables
    local optional_vars=(
        "AZURE_SERVICE_CONNECTION_NAME"
        "DEPLOYMENT_LOCATION"
    )
    
    echo ""
    log_info "Checking required variables..."
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "  $var is not set (REQUIRED)"
            ((errors++))
        else
            # Mask sensitive values
            if [[ "$var" == "ADO_PAT_TOKEN" ]]; then
                log_success "  $var is set (value: ****masked****)"
            else
                log_success "  $var is set (value: ${!var})"
            fi
        fi
    done
    
    echo ""
    log_info "Checking optional variables..."
    for var in "${optional_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_warn "  $var is not set (will use default or be prompted)"
            ((warnings++))
        else
            log_success "  $var is set (value: ${!var})"
        fi
    done
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        log_error "Missing $errors required variable(s) in config.sh"
        return 1
    fi
    
    if [[ $warnings -gt 0 ]]; then
        echo ""
        log_warn "$warnings optional variable(s) not set - defaults will be used"
    fi
    
    log_success "All required configuration variables are set"
    return 0
}

check_ado_connection() {
    log_step "Checking Azure DevOps connection..."
    
    local config_file="${SCRIPT_DIR}/config.sh"
    source "$config_file"
    
    # Configure Azure DevOps defaults
    export AZURE_DEVOPS_EXT_PAT="${ADO_PAT_TOKEN}"
    
    if az devops project list --org "${ADO_ORGANIZATION_URL}" --query "[0].name" -o tsv &> /dev/null; then
        log_success "Successfully connected to Azure DevOps organization"
        
        # Verify project exists
        if az devops project show --project "${ADO_PROJECT_NAME}" --org "${ADO_ORGANIZATION_URL}" &> /dev/null; then
            log_success "Project '${ADO_PROJECT_NAME}' exists and is accessible"
            return 0
        else
            log_error "Project '${ADO_PROJECT_NAME}' not found or not accessible"
            echo ""
            echo "  Available projects:"
            az devops project list --org "${ADO_ORGANIZATION_URL}" --query "[].name" -o tsv 2>/dev/null | sed 's/^/    - /'
            echo ""
            return 1
        fi
    else
        log_error "Failed to connect to Azure DevOps"
        echo ""
        echo "  Please verify:"
        echo "  - ADO_ORGANIZATION_URL is correct (e.g., https://dev.azure.com/myorg)"
        echo "  - ADO_PAT_TOKEN has sufficient permissions"
        echo ""
        echo "  Required PAT permissions:"
        echo "    - Variable Groups: Read & Manage (under Pipelines)"
        echo "    - Environment: Read & Manage (under Pipelines)"
        echo "    - Project and Team: Read (under Project)"
        echo ""
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "============================================================================="
    echo "  Azure DevOps Setup - Prerequisites Check"
    echo "============================================================================="
    echo ""
    
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    
    # Check each prerequisite
    checks=(
        "check_azure_cli"
        "check_azure_devops_extension"
        "check_jq"
        "check_config_file"
    )
    
    for check in "${checks[@]}"; do
        ((total_checks++))
        if $check; then
            ((passed_checks++))
        else
            ((failed_checks++))
        fi
        echo ""
    done
    
    # Only check config variables if config file exists
    if [[ -f "${SCRIPT_DIR}/config.sh" ]]; then
        ((total_checks++))
        if check_config_variables; then
            ((passed_checks++))
        else
            ((failed_checks++))
        fi
        echo ""
        
        # Only check ADO connection if config variables are set
        if [[ $failed_checks -eq 0 ]]; then
            ((total_checks++))
            if check_ado_connection; then
                ((passed_checks++))
            else
                ((failed_checks++))
            fi
            echo ""
        fi
    fi
    
    # Azure login check (optional - doesn't block)
    ((total_checks++))
    if check_azure_login; then
        ((passed_checks++))
    else
        ((failed_checks++))
    fi
    echo ""
    
    # Summary
    echo "============================================================================="
    echo "  Summary: ${passed_checks}/${total_checks} checks passed"
    echo "============================================================================="
    
    if [[ $failed_checks -eq 0 ]]; then
        log_success "All prerequisites met! You can run the variable group scripts."
        return 0
    else
        log_error "${failed_checks} prerequisite check(s) failed. Please fix the issues above."
        return 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
