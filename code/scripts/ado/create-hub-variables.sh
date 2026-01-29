#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update Hub Variables
# =============================================================================
# This script creates or updates the 'hub-variables' variable group
# containing variables used by the hub infrastructure deployment pipeline.
#
# Parameter Placement Strategy:
# - This variable group only contains STRING values that may need organization-wide updates
# - Stable configuration (VNet address space, IPAM pool settings) is in bicepparam files
# - Runtime values (environment, location, instance) are pipeline parameters
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

GROUP_NAME="hub-variables"
GROUP_DESCRIPTION="Variables for hub infrastructure deployment pipeline. Contains string values only (subscription ID, resource IDs, DNS zone name, management group ID). Stable configuration is in bicepparam files."

# Default values (can be overridden in config.sh)
# Subscription ID for hub/connectivity resources
HUB_SUBSCRIPTION_ID="${HUB_SUBSCRIPTION_ID:-}"

# Log Analytics Workspace Resource ID from monitoring infrastructure
LOG_ANALYTICS_WORKSPACE_RESOURCE_ID="${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID:-}"

# Organization-wide private DNS zone name
PRIVATE_DNS_ZONE_NAME="${PRIVATE_DNS_ZONE_NAME:-internal.organization.com}"

# AVNM Management Group ID
AVNM_MANAGEMENT_GROUP_ID="${AVNM_MANAGEMENT_GROUP_ID:-mg-connectivity}"

# Key Vault Admin Principal ID (Object ID for Key Vault Administrator role)
KEY_VAULT_ADMIN_PRINCIPAL_ID="${KEY_VAULT_ADMIN_PRINCIPAL_ID:-}"

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

# Create or update the hub-variables group
create_hub_variables_group() {
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
    
    # Subscription ID for hub/connectivity resources
    set_variable "$group_id" "hubSubscriptionId" "${HUB_SUBSCRIPTION_ID}"
    
    # Log Analytics Workspace Resource ID (from monitoring infrastructure)
    set_variable "$group_id" "logAnalyticsWorkspaceResourceId" "${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID}"
    
    # Private DNS Zone name
    set_variable "$group_id" "privateDnsZoneName" "${PRIVATE_DNS_ZONE_NAME}"
    
    # AVNM Management Group ID
    set_variable "$group_id" "avnmManagementGroupId" "${AVNM_MANAGEMENT_GROUP_ID}"
    
    # Key Vault Admin Principal ID (optional)
    set_variable "$group_id" "keyVaultAdminPrincipalId" "${KEY_VAULT_ADMIN_PRINCIPAL_ID}"
    
    # Remove the dummy placeholder variable if it exists
    delete_variable "$group_id" "dummy"
    
    log_success "Variable group '${GROUP_NAME}' configured successfully"
    
    # Display the variables
    echo ""
    log_info "Variables in '${GROUP_NAME}':"
    if [[ -z "${HUB_SUBSCRIPTION_ID}" ]]; then
        echo "  - hubSubscriptionId: (empty - set after subscription is created)"
    else
        echo "  - hubSubscriptionId: ${HUB_SUBSCRIPTION_ID}"
    fi
    if [[ -z "${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID}" ]]; then
        echo "  - logAnalyticsWorkspaceResourceId: (empty - set after monitoring deployment)"
    else
        echo "  - logAnalyticsWorkspaceResourceId: ${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID}"
    fi
    echo "  - privateDnsZoneName: ${PRIVATE_DNS_ZONE_NAME}"
    echo "  - avnmManagementGroupId: ${AVNM_MANAGEMENT_GROUP_ID}"
    if [[ -z "${KEY_VAULT_ADMIN_PRINCIPAL_ID}" ]]; then
        echo "  - keyVaultAdminPrincipalId: (empty - optional)"
    else
        echo "  - keyVaultAdminPrincipalId: ${KEY_VAULT_ADMIN_PRINCIPAL_ID}"
    fi
    
    echo ""
    log_info "Note: Stable configuration (VNet address space, IPAM pool settings) is defined in bicepparam files."
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create/update variable group: ${GROUP_NAME}"
    echo ""
    log_info "Variables that would be set:"
    if [[ -z "${HUB_SUBSCRIPTION_ID}" ]]; then
        echo "  - hubSubscriptionId: (empty - set after subscription is created)"
    else
        echo "  - hubSubscriptionId: ${HUB_SUBSCRIPTION_ID}"
    fi
    if [[ -z "${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID}" ]]; then
        echo "  - logAnalyticsWorkspaceResourceId: (empty - set after monitoring deployment)"
    else
        echo "  - logAnalyticsWorkspaceResourceId: ${LOG_ANALYTICS_WORKSPACE_RESOURCE_ID}"
    fi
    echo "  - privateDnsZoneName: ${PRIVATE_DNS_ZONE_NAME}"
    echo "  - avnmManagementGroupId: ${AVNM_MANAGEMENT_GROUP_ID}"
    if [[ -z "${KEY_VAULT_ADMIN_PRINCIPAL_ID}" ]]; then
        echo "  - keyVaultAdminPrincipalId: (empty - optional)"
    else
        echo "  - keyVaultAdminPrincipalId: ${KEY_VAULT_ADMIN_PRINCIPAL_ID}"
    fi
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
    echo ""
    log_info "Note: Stable configuration (VNet address space, IPAM pool settings) is defined in bicepparam files."
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update the 'hub-variables' Azure DevOps variable group."
    echo ""
    echo "This variable group contains STRING values only that may need organization-wide updates:"
    echo "  - hubSubscriptionId: The subscription ID for hub/connectivity resources"
    echo "  - logAnalyticsWorkspaceResourceId: Resource ID of Log Analytics Workspace"
    echo "  - privateDnsZoneName: Organization-wide private DNS zone name"
    echo "  - avnmManagementGroupId: Management group ID for AVNM scope"
    echo "  - keyVaultAdminPrincipalId: Service principal Object ID for Key Vault access (optional)"
    echo ""
    echo "Note: Stable configuration (VNet address space, IPAM pool settings, optional resource flags)"
    echo "is defined in bicepparam files or as pipeline parameters, not in variable groups."
    echo "ADO variable groups only support strings."
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
    create_hub_variables_group
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
