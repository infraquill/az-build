#!/bin/bash
# =============================================================================
# NuclearIMS Infrastructure - Create Platform Admin Service Principal
# =============================================================================
# This script creates the Platform Admin service principal with all required
# permissions for bootstrap and subscription vending operations.
#
# Required Permissions:
# - Owner on Tenant Root Management Group (full hierarchy access)
# - Application Administrator in Microsoft Entra ID (via Graph API)
# - Billing Account Owner (for subscription creation - manual)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config.sh"

echo ""
echo "============================================================================="
echo " NuclearIMS Infrastructure - Create Platform Admin Service Principal"
echo "============================================================================="
echo ""

# =============================================================================
# Verify Login
# =============================================================================
log_step "Verifying Azure login..."

if ! az account show &> /dev/null; then
    log_error "Not logged into Azure CLI. Please run: az login"
    exit 1
fi

CURRENT_USER=$(az account show --query user.name -o tsv)
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
log_success "Logged in as: $CURRENT_USER"
echo ""

# =============================================================================
# Check for Existing Service Principal
# =============================================================================
log_step "Checking for existing service principal: $PLATFORM_ADMIN_SP_NAME"

EXISTING_APP_ID=""
EXISTING_SP_ID=""

# Check if app registration exists
EXISTING_APP=$(az ad app list --display-name "$PLATFORM_ADMIN_SP_NAME" --query "[0]" -o json 2>/dev/null || echo "null")

EXISTING_APP_OBJECT_ID=""

if [[ "$EXISTING_APP" != "null" ]] && [[ -n "$EXISTING_APP" ]]; then
    EXISTING_APP_ID=$(echo "$EXISTING_APP" | jq -r '.appId')
    EXISTING_APP_OBJECT_ID=$(echo "$EXISTING_APP" | jq -r '.id')
    log_info "Found existing app registration:"
    log_info "  Application (Client) ID: $EXISTING_APP_ID"
    log_info "  App Object ID: $EXISTING_APP_OBJECT_ID"
    
    # Check if service principal exists
    EXISTING_SP=$(az ad sp show --id "$EXISTING_APP_ID" --query "id" -o tsv 2>/dev/null || echo "")
    if [[ -n "$EXISTING_SP" ]]; then
        EXISTING_SP_ID="$EXISTING_SP"
        log_info "Found existing service principal (Enterprise App) Object ID: $EXISTING_SP_ID"
    fi
fi

echo ""

# =============================================================================
# Create or Update App Registration
# =============================================================================
log_step "Creating/updating app registration..."

if [[ -n "$EXISTING_APP_ID" ]]; then
    log_info "Using existing app registration"
    APP_ID="$EXISTING_APP_ID"
    APP_OBJECT_ID="$EXISTING_APP_OBJECT_ID"
else
    log_info "Creating new app registration: $PLATFORM_ADMIN_SP_NAME"
    
    APP_RESULT=$(az ad app create \
        --display-name "$PLATFORM_ADMIN_SP_NAME" \
        --sign-in-audience "AzureADMyOrg" \
        --query "{appId: appId, id: id}" \
        -o json)
    
    APP_ID=$(echo "$APP_RESULT" | jq -r '.appId')
    APP_OBJECT_ID=$(echo "$APP_RESULT" | jq -r '.id')
    
    log_success "Created app registration"
    log_info "  Application (Client) ID: $APP_ID"
    log_info "  App Object ID: $APP_OBJECT_ID"
    
    # Wait for propagation
    sleep 5
fi

echo ""

# =============================================================================
# Create Service Principal
# =============================================================================
log_step "Creating/updating service principal..."

if [[ -n "$EXISTING_SP_ID" ]]; then
    log_info "Using existing service principal (Enterprise Application)"
    SP_OBJECT_ID="$EXISTING_SP_ID"
else
    log_info "Creating service principal (Enterprise Application) for app: $APP_ID"
    
    SP_RESULT=$(az ad sp create --id "$APP_ID" --query "id" -o tsv)
    SP_OBJECT_ID="$SP_RESULT"
    
    log_success "Created service principal (Enterprise Application)"
    log_info "  Service Principal Object ID: $SP_OBJECT_ID"
    log_info "  (Note: Federated credentials are configured on the App Registration, not here)"
    
    # Wait for propagation
    sleep 10
fi

echo ""

# =============================================================================
# Get Subscription IDs
# =============================================================================
log_step "Getting subscription IDs..."

MGMT_SUB_ID=$(az account list --query "[?name=='$MANAGEMENT_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")
CONN_SUB_ID=$(az account list --query "[?name=='$CONNECTIVITY_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")

if [[ -z "$MGMT_SUB_ID" ]]; then
    log_warn "Management subscription '$MANAGEMENT_SUBSCRIPTION_NAME' not found"
    log_info "Run: bash check-prerequisites.sh"
else
    log_info "Management Subscription ID: $MGMT_SUB_ID"
fi

if [[ -z "$CONN_SUB_ID" ]]; then
    log_warn "Connectivity subscription '$CONNECTIVITY_SUBSCRIPTION_NAME' not found"
    log_info "It will be created by the terraform-foundation.yml pipeline"
else
    log_info "Connectivity Subscription ID: $CONN_SUB_ID"
fi

echo ""

# =============================================================================
# Assign RBAC Roles
# =============================================================================
log_step "Assigning RBAC roles..."

assign_role() {
    local role=$1
    local scope=$2
    local description=$3
    
    log_info "Assigning $role at $description..."
    
    # Check if assignment already exists
    EXISTING=$(az role assignment list \
        --assignee "$SP_OBJECT_ID" \
        --role "$role" \
        --scope "$scope" \
        --query "[0].id" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$EXISTING" ]]; then
        log_info "  Role already assigned"
        return 0
    fi
    
    if az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "$role" \
        --scope "$scope" &> /dev/null; then
        log_success "  Role assigned successfully"
        return 0
    else
        log_error "  Failed to assign role"
        return 1
    fi
}

ROLE_ERRORS=0

# Owner on Tenant Root Management Group (for full hierarchy access)
log_info ""
log_info "Tenant Root Management Group Permission:"

if ! assign_role "Owner" "/providers/Microsoft.Management/managementGroups/$AAD_TENANT_ID" "Tenant Root Management Group"; then
    log_warn "  Could not assign Owner at Tenant Root. You may need to enable elevated access:"
    log_warn "    Azure Portal > Microsoft Entra ID > Properties > Access management for Azure resources > Yes"
    ((ROLE_ERRORS++))
fi

# Owner on Subscriptions (if they exist at this point)
log_info ""
log_info "Subscription Permissions:"

if [[ -n "$MGMT_SUB_ID" ]]; then
    if ! assign_role "Owner" "/subscriptions/$MGMT_SUB_ID" "$MANAGEMENT_SUBSCRIPTION_NAME"; then
        ((ROLE_ERRORS++))
    fi
else
    log_warn "Skipping Management subscription role (subscription not found)"
fi

if [[ -n "$CONN_SUB_ID" ]]; then
    if ! assign_role "Owner" "/subscriptions/$CONN_SUB_ID" "$CONNECTIVITY_SUBSCRIPTION_NAME"; then
        ((ROLE_ERRORS++))
    fi
else
    log_warn "Skipping Connectivity subscription role (subscription not found)"
fi

echo ""

# =============================================================================
# Azure AD Role Assignment (Application Administrator)
# =============================================================================
log_step "Assigning Application Administrator role via Microsoft Graph API..."

# Application Administrator role template ID (well-known, same across all tenants)
# See: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference
APP_ADMIN_ROLE_TEMPLATE_ID="9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"

# Check if the role is already assigned
log_info "Checking if Application Administrator role is already assigned..."

EXISTING_ROLE_ASSIGNMENT=$(az rest \
    --method GET \
    --url "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?\$filter=principalId eq '$SP_OBJECT_ID' and roleDefinitionId eq '$APP_ADMIN_ROLE_TEMPLATE_ID'" \
    --query "value[0].id" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_ROLE_ASSIGNMENT" ]]; then
    log_info "Application Administrator role is already assigned"
    APP_ADMIN_ASSIGNED=true
else
    log_info "Assigning Application Administrator role..."
    
    # Assign the role using Microsoft Graph API
    ROLE_ASSIGNMENT_RESULT=$(az rest \
        --method POST \
        --url "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" \
        --headers "Content-Type=application/json" \
        --body "{
            \"@odata.type\": \"#microsoft.graph.unifiedRoleAssignment\",
            \"principalId\": \"$SP_OBJECT_ID\",
            \"roleDefinitionId\": \"$APP_ADMIN_ROLE_TEMPLATE_ID\",
            \"directoryScopeId\": \"/\"
        }" 2>&1) || {
            log_warn "Could not assign Application Administrator role via API"
            log_info "Error: $ROLE_ASSIGNMENT_RESULT"
            APP_ADMIN_ASSIGNED=false
        }
    
    if [[ "$ROLE_ASSIGNMENT_RESULT" == *"id"* ]]; then
        log_success "Application Administrator role assigned successfully"
        APP_ADMIN_ASSIGNED=true
    fi
fi

if [[ "${APP_ADMIN_ASSIGNED:-false}" != "true" ]]; then
    echo ""
    echo "============================================================================="
    echo " MANUAL STEP REQUIRED: Azure AD Role Assignment"
    echo "============================================================================="
    echo ""
    echo " Could not automatically assign the 'Application Administrator' role."
    echo " This role is needed to create app registrations for workload subscriptions."
    echo ""
    echo " To assign this role manually:"
    echo ""
    echo "   1. Go to Azure Portal: https://portal.azure.com"
    echo "   2. Navigate to: Microsoft Entra ID > Roles and administrators"
    echo "   3. Search for: Application Administrator"
    echo "   4. Click: Add assignments"
    echo "   5. Search for: $PLATFORM_ADMIN_SP_NAME"
    echo "   6. Select the service principal and click: Add"
    echo ""
    echo " Service Principal Details:"
    echo "   Name:      $PLATFORM_ADMIN_SP_NAME"
    echo "   Client ID: $APP_ID"
    echo "   Object ID: $SP_OBJECT_ID"
    echo ""
    echo "============================================================================="
    echo ""
    
    read -r -p "Press Enter once you have assigned the Application Administrator role..."
fi

echo ""

# =============================================================================
# Billing Role Assignment (if needed)
# =============================================================================
echo ""
echo "============================================================================="
echo " OPTIONAL: Billing Permissions for Subscription Creation"
echo "============================================================================="
echo ""
echo " If you want the service principal to create subscriptions automatically,"
echo " you need to grant billing permissions:"
echo ""
echo "   1. Go to Azure Portal: https://portal.azure.com"
echo "   2. Navigate to: Cost Management + Billing"
echo "   3. Select your billing account"
echo "   4. Go to: Access control (IAM)"
echo "   5. Add role assignment:"
echo "      - Role: Billing Account Contributor or Owner"
echo "      - Assign to: $PLATFORM_ADMIN_SP_NAME"
echo ""
echo " Alternatively, subscription vending can work with pre-created subscriptions"
echo " if billing permissions are not available."
echo ""
echo "============================================================================="
echo ""

# =============================================================================
# Output Summary
# =============================================================================
echo "============================================================================="
echo " Service Principal Created Successfully"
echo "============================================================================="
echo ""
echo " App Registration (where federated credentials are configured):"
echo "   Display Name:           $PLATFORM_ADMIN_SP_NAME"
echo "   Application (Client) ID: $APP_ID"
echo "   App Object ID:          $APP_OBJECT_ID"
echo "   Tenant ID:              $AAD_TENANT_ID"
echo ""
echo " Enterprise Application (Service Principal):"
echo "   SP Object ID:           $SP_OBJECT_ID"
echo ""
echo " NOTE: To configure federated credentials, go to:"
echo "   Azure Portal > App Registrations > $PLATFORM_ADMIN_SP_NAME"
echo "   NOT Enterprise Applications!"
echo ""
echo " RBAC Assignments:"
echo "   [x] Owner on Tenant Root Management Group (full hierarchy access)"
if [[ -n "$MGMT_SUB_ID" ]]; then
    echo "   [x] Owner on $MANAGEMENT_SUBSCRIPTION_NAME"
else
    echo "   [ ] Owner on $MANAGEMENT_SUBSCRIPTION_NAME (subscription not found)"
fi
if [[ -n "$CONN_SUB_ID" ]]; then
    echo "   [x] Owner on $CONNECTIVITY_SUBSCRIPTION_NAME"
else
    echo "   [ ] Owner on $CONNECTIVITY_SUBSCRIPTION_NAME (subscription not found)"
fi
echo ""
echo " Microsoft Entra ID Roles:"
if [[ "${APP_ADMIN_ASSIGNED:-false}" == "true" ]]; then
    echo "   [x] Application Administrator"
else
    echo "   [ ] Application Administrator (manual assignment required)"
fi
echo ""
echo " Billing Permissions (Optional):"
echo "   [ ] Billing Account Contributor/Owner"
echo ""

# Save to file for reference
OUTPUT_FILE="${SCRIPT_DIR}/.platform-admin-sp.env"
cat > "$OUTPUT_FILE" <<EOF
# Platform Admin Service Principal
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# WARNING: Keep this file secure!

PLATFORM_ADMIN_SP_NAME="$PLATFORM_ADMIN_SP_NAME"

# Application (Client) ID - used for authentication
PLATFORM_ADMIN_CLIENT_ID="$APP_ID"

# App Registration Object ID - use this for federated credentials
# Find at: Azure Portal > App Registrations > $PLATFORM_ADMIN_SP_NAME
PLATFORM_ADMIN_APP_OBJECT_ID="$APP_OBJECT_ID"

# Service Principal (Enterprise App) Object ID - use this for RBAC
# Find at: Azure Portal > Enterprise Applications > $PLATFORM_ADMIN_SP_NAME
PLATFORM_ADMIN_SP_OBJECT_ID="$SP_OBJECT_ID"

# Tenant ID
TENANT_ID="$AAD_TENANT_ID"

# DEPRECATED - kept for backward compatibility
PLATFORM_ADMIN_OBJECT_ID="$SP_OBJECT_ID"
EOF

log_success "Service principal details saved to: $OUTPUT_FILE"
echo ""

# =============================================================================
# Summary
# =============================================================================
if [[ $ROLE_ERRORS -eq 0 ]]; then
    log_success "Platform Admin service principal setup completed!"
    echo ""
    echo "Next step: bash create-service-connection.sh"
else
    log_warn "Completed with $ROLE_ERRORS role assignment warning(s)"
    log_info "Review the warnings above and ensure all required roles are assigned"
fi

echo ""

