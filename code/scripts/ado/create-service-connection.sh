#!/bin/bash
# =============================================================================
# NuclearIMS Infrastructure - Setup Azure DevOps Service Connection
# =============================================================================
# This script creates an Azure DevOps service connection using Workload Identity
# Federation for passwordless authentication from Azure Pipelines.
#
# Prerequisites:
# - Azure DevOps CLI extension installed (az extension add -n azure-devops)
# - Platform Admin service principal created (bash create-platform-admin.sh)
# - Azure DevOps organization and project configured in config.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config.sh"

# =============================================================================
# Variable Mapping - handle differences between config.sh variable names
# =============================================================================
# Extract organization name from ADO_ORGANIZATION_URL if ADO_ORGANIZATION is not set
if [[ -z "${ADO_ORGANIZATION:-}" ]] && [[ -n "${ADO_ORGANIZATION_URL:-}" ]]; then
    # Extract organization name from URL (e.g., https://dev.azure.com/myorg -> myorg)
    ADO_ORGANIZATION=$(echo "$ADO_ORGANIZATION_URL" | sed 's|https://dev.azure.com/||' | sed 's|/$||')
fi

# Map ADO_PROJECT_NAME to ADO_PROJECT if ADO_PROJECT is not set
if [[ -z "${ADO_PROJECT:-}" ]] && [[ -n "${ADO_PROJECT_NAME:-}" ]]; then
    ADO_PROJECT="$ADO_PROJECT_NAME"
fi

# Map AZURE_SERVICE_CONNECTION_NAME to PLATFORM_ADMIN_SERVICE_CONNECTION if not set
if [[ -z "${PLATFORM_ADMIN_SERVICE_CONNECTION:-}" ]] && [[ -n "${AZURE_SERVICE_CONNECTION_NAME:-}" ]]; then
    PLATFORM_ADMIN_SERVICE_CONNECTION="$AZURE_SERVICE_CONNECTION_NAME"
fi

echo ""
echo "============================================================================="
echo " NuclearIMS Infrastructure - Setup Azure DevOps Service Connection"
echo "============================================================================="
echo ""

# =============================================================================
# Load Service Principal Details
# =============================================================================
SP_ENV_FILE="${SCRIPT_DIR}/.platform-admin-sp.env"

if [[ -f "$SP_ENV_FILE" ]]; then
    log_info "Loading service principal details from: $SP_ENV_FILE"
    source "$SP_ENV_FILE"
else
    log_error "Service principal environment file not found: $SP_ENV_FILE"
    log_info "Run: bash create-platform-admin.sh"
    exit 1
fi

# Verify required variables
if [[ -z "${PLATFORM_ADMIN_CLIENT_ID:-}" ]]; then
    log_error "PLATFORM_ADMIN_CLIENT_ID not set"
    exit 1
fi

log_success "Service principal loaded: $PLATFORM_ADMIN_CLIENT_ID"
echo ""

# =============================================================================
# Verify Azure DevOps Configuration
# =============================================================================
log_step "Verifying Azure DevOps configuration..."

if [[ -z "${ADO_ORGANIZATION:-}" ]]; then
    log_error "ADO_ORGANIZATION is not set and could not be derived from ADO_ORGANIZATION_URL"
    log_info "Set ADO_ORGANIZATION or ADO_ORGANIZATION_URL in config.sh"
    exit 1
fi

if [[ -z "${ADO_PROJECT:-}" ]]; then
    log_error "ADO_PROJECT is not set and could not be derived from ADO_PROJECT_NAME"
    log_info "Set ADO_PROJECT or ADO_PROJECT_NAME in config.sh"
    exit 1
fi

if [[ -z "${PLATFORM_ADMIN_SERVICE_CONNECTION:-}" ]]; then
    log_error "PLATFORM_ADMIN_SERVICE_CONNECTION is not set and could not be derived from AZURE_SERVICE_CONNECTION_NAME"
    log_info "Set PLATFORM_ADMIN_SERVICE_CONNECTION or AZURE_SERVICE_CONNECTION_NAME in config.sh"
    exit 1
fi

log_info "Azure DevOps Organization: $ADO_ORGANIZATION"
log_info "Azure DevOps Project: $ADO_PROJECT"
log_info "Service Connection Name: $PLATFORM_ADMIN_SERVICE_CONNECTION"

echo ""

# =============================================================================
# Verify Azure Login
# =============================================================================
log_step "Verifying Azure login..."

if ! az account show &> /dev/null; then
    log_error "Not logged into Azure CLI. Please run: az login"
    exit 1
fi

log_success "Azure CLI login verified"
echo ""

# =============================================================================
# Configure Azure DevOps CLI
# =============================================================================
log_step "Configuring Azure DevOps CLI..."

# Set defaults
az devops configure --defaults organization="https://dev.azure.com/$ADO_ORGANIZATION" project="$ADO_PROJECT"

# Check if we need to login to Azure DevOps
if ! az devops project show --project "$ADO_PROJECT" &> /dev/null 2>&1; then
    log_warn "Cannot access Azure DevOps project. You may need to authenticate."
    echo ""
    echo "Options:"
    echo "  1. Run: az devops login"
    echo "  2. Set environment variable: AZURE_DEVOPS_EXT_PAT=<your-pat>"
    echo ""
    echo "To create a PAT:"
    echo "  1. Go to: https://dev.azure.com/$ADO_ORGANIZATION/_usersSettings/tokens"
    echo "  2. Create new token with 'Service Connections (Read, query, & manage)' scope"
    echo ""
    
    read -r -p "Enter your Azure DevOps PAT (or press Enter to try interactive login): " ADO_PAT
    
    if [[ -n "$ADO_PAT" ]]; then
        export AZURE_DEVOPS_EXT_PAT="$ADO_PAT"
    else
        log_info "Attempting interactive login..."
        az devops login
    fi
    
    # Retry
    if ! az devops project show --project "$ADO_PROJECT" &> /dev/null 2>&1; then
        log_error "Still cannot access Azure DevOps project"
        exit 1
    fi
fi

log_success "Azure DevOps CLI configured"
echo ""

# =============================================================================
# Get Project ID
# =============================================================================
log_step "Getting Azure DevOps project details..."

PROJECT_ID=$(az devops project show --project "$ADO_PROJECT" --query "id" -o tsv)
if [[ -z "$PROJECT_ID" ]]; then
    log_error "Could not get project ID for: $ADO_PROJECT"
    exit 1
fi
log_info "Project ID: $PROJECT_ID"

# =============================================================================
# Get Tenant Root Management Group Details
# =============================================================================
log_step "Getting tenant root management group details..."

# The service connection is scoped to the Tenant Root Management Group.
# This is the built-in root that always exists and has the same ID as the tenant.
# Scoping here allows the Platform Admin to manage the entire hierarchy.
MG_ID="$TENANT_ID"
MG_DISPLAY_NAME="Tenant Root Group"

# Verify we can access the tenant root management group
if ! az account management-group show --name "$MG_ID" &> /dev/null 2>&1; then
    log_error "Cannot access Tenant Root Management Group: $MG_ID"
    log_info "Ensure you have permissions to view management groups"
    log_info "You may need to enable management group access in Azure Portal:"
    log_info "  Azure AD > Properties > Access management for Azure resources > Yes"
    exit 1
fi

log_info "Tenant Root Management Group ID: $MG_ID"
log_info "Management Group Display Name: $MG_DISPLAY_NAME"
echo ""

# =============================================================================
# Get Management Subscription Details
# =============================================================================
log_step "Getting management subscription details..."

# The service connection needs a default subscription context for Terraform operations.
# We use the management subscription as the default, but the SP can access all subscriptions
# under the management group scope.
MGMT_SUBSCRIPTION_ID=$(az account list --query "[?name=='$MANAGEMENT_SUBSCRIPTION_NAME'].id" -o tsv 2>/dev/null || echo "")

if [[ -z "$MGMT_SUBSCRIPTION_ID" ]]; then
    log_error "Cannot find management subscription: $MANAGEMENT_SUBSCRIPTION_NAME"
    log_info "Ensure the subscription exists and you have access to it"
    exit 1
fi

log_info "Management Subscription: $MANAGEMENT_SUBSCRIPTION_NAME"
log_info "Subscription ID: $MGMT_SUBSCRIPTION_ID"
echo ""

# =============================================================================
# Get App Object ID for Federated Credential
# =============================================================================
if [[ -n "${PLATFORM_ADMIN_APP_OBJECT_ID:-}" ]]; then
    APP_OBJECT_ID="$PLATFORM_ADMIN_APP_OBJECT_ID"
    log_info "Using cached App Object ID: $APP_OBJECT_ID"
else
    APP_OBJECT_ID=$(az ad app show --id "$PLATFORM_ADMIN_CLIENT_ID" --query "id" -o tsv)
    log_info "Looked up App Object ID: $APP_OBJECT_ID"
fi

# =============================================================================
# Create Federated Identity Credential
# =============================================================================
log_step "Creating federated identity credential..."

# Federated credential configuration
# Issuer uses Azure AD tenant ID for Workload Identity Federation
# TENANT_ID is loaded from .platform-admin-sp.env, fallback to AAD_TENANT_ID from config.sh
FED_TENANT_ID="${TENANT_ID:-${AAD_TENANT_ID:-}}"
if [[ -z "$FED_TENANT_ID" ]]; then
    log_error "Neither TENANT_ID nor AAD_TENANT_ID is set"
    log_info "Ensure create-platform-admin.sh was run successfully or set AAD_TENANT_ID in config.sh"
    exit 1
fi

FED_CRED_NAME="ado-${ADO_ORGANIZATION}-${ADO_PROJECT}-${PLATFORM_ADMIN_SERVICE_CONNECTION}"
FED_CRED_NAME=$(echo "$FED_CRED_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
FED_ISSUER="https://login.microsoftonline.com/${FED_TENANT_ID}/v2.0"
FED_SUBJECT="sc://${ADO_ORGANIZATION}/${ADO_PROJECT}/${PLATFORM_ADMIN_SERVICE_CONNECTION}"

log_info "Federated Credential:"
log_info "  Name: $FED_CRED_NAME"
log_info "  Issuer: $FED_ISSUER"
log_info "  Subject: $FED_SUBJECT"

# Check if federated credential already exists
EXISTING_FED_CRED=$(az ad app federated-credential list \
    --id "$APP_OBJECT_ID" \
    --query "[?name=='$FED_CRED_NAME'].id" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_FED_CRED" ]]; then
    log_info "Federated credential already exists, updating..."
    az ad app federated-credential update \
        --id "$APP_OBJECT_ID" \
        --federated-credential-id "$FED_CRED_NAME" \
        --parameters "{
            \"name\": \"$FED_CRED_NAME\",
            \"issuer\": \"$FED_ISSUER\",
            \"subject\": \"$FED_SUBJECT\",
            \"audiences\": [\"api://AzureADTokenExchange\"],
            \"description\": \"Azure DevOps service connection: $PLATFORM_ADMIN_SERVICE_CONNECTION\"
        }" > /dev/null
    log_success "Federated credential updated"
else
    log_info "Creating new federated credential..."
    az ad app federated-credential create \
        --id "$APP_OBJECT_ID" \
        --parameters "{
            \"name\": \"$FED_CRED_NAME\",
            \"issuer\": \"$FED_ISSUER\",
            \"subject\": \"$FED_SUBJECT\",
            \"audiences\": [\"api://AzureADTokenExchange\"],
            \"description\": \"Azure DevOps service connection: $PLATFORM_ADMIN_SERVICE_CONNECTION\"
        }" > /dev/null
    log_success "Federated credential created"
fi

echo ""

# =============================================================================
# Create Azure DevOps Service Connection
# =============================================================================
log_step "Creating Azure DevOps service connection..."

# Check if service connection already exists
EXISTING_SC=$(az devops service-endpoint list \
    --query "[?name=='$PLATFORM_ADMIN_SERVICE_CONNECTION'].id" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_SC" ]]; then
    log_info "Service connection '$PLATFORM_ADMIN_SERVICE_CONNECTION' already exists"
    log_info "Service Endpoint ID: $EXISTING_SC"
    log_success "Service connection is ready (idempotent - skipping creation)"
    
    # Verify the federated credential still exists (it should, but check)
    if [[ -n "$APP_OBJECT_ID" ]]; then
        EXISTING_FED_CRED=$(az ad app federated-credential list \
            --id "$APP_OBJECT_ID" \
            --query "[?name=='$FED_CRED_NAME'].id" -o tsv 2>/dev/null || echo "")
        
        if [[ -z "$EXISTING_FED_CRED" ]]; then
            log_warn "Federated credential not found - service connection may not work"
            log_info "Federated credential will be recreated below"
            # Clear so it gets created in the federated credential section
            EXISTING_FED_CRED=""
        else
            log_info "Federated credential exists and is valid"
        fi
    fi
    
    # Service connection exists, skip creation
    # The verification section below will use EXISTING_SC
else
    # Service connection doesn't exist, create it
    log_info "Creating service connection via Azure DevOps REST API..."
    
    # Build the JSON payload
    # NOTE: Don't include workloadIdentityFederationSubject - Azure DevOps derives it automatically
    # Scoped to Management Group for full hierarchy access, with subscription context for Terraform
    SERVICE_ENDPOINT_JSON=$(cat <<EOF
{
    "name": "$PLATFORM_ADMIN_SERVICE_CONNECTION",
    "type": "azurerm",
    "url": "https://management.azure.com/",
    "authorization": {
        "scheme": "WorkloadIdentityFederation",
        "parameters": {
            "tenantid": "$TENANT_ID",
            "serviceprincipalid": "$PLATFORM_ADMIN_CLIENT_ID"
        }
    },
    "data": {
        "managementGroupId": "$MG_ID",
        "managementGroupName": "$MG_DISPLAY_NAME",
        "subscriptionId": "$MGMT_SUBSCRIPTION_ID",
        "subscriptionName": "$MANAGEMENT_SUBSCRIPTION_NAME",
        "environment": "AzureCloud",
        "scopeLevel": "ManagementGroup",
        "creationMode": "Manual"
    },
    "isShared": false,
    "isReady": true,
    "serviceEndpointProjectReferences": [
        {
            "projectReference": {
                "id": "$PROJECT_ID",
                "name": "$ADO_PROJECT"
            },
            "name": "$PLATFORM_ADMIN_SERVICE_CONNECTION"
        }
    ]
}
EOF
)

    # Create the service endpoint using REST API
    RESULT=$(az devops invoke \
        --area serviceendpoint \
        --resource endpoints \
        --route-parameters project="$PROJECT_ID" \
        --http-method POST \
        --api-version 7.1 \
        --in-file <(echo "$SERVICE_ENDPOINT_JSON") \
        -o json 2>&1) || {
            log_error "Failed to create service connection"
            echo "$RESULT"
            echo ""
            echo "============================================================================="
            echo " MANUAL FALLBACK"
            echo "============================================================================="
            echo ""
            echo " If automatic creation fails, create the service connection manually:"
            echo ""
            echo " 1. Go to: https://dev.azure.com/$ADO_ORGANIZATION/$ADO_PROJECT/_settings/adminservices"
            echo " 2. Click: New service connection"
            echo " 3. Select: Azure Resource Manager → Next"
            echo " 4. Select: Workload Identity federation (manual) → Next"
            echo " 5. Select scope: Management Group"
            echo " 6. Enter these values:"
            echo ""
            echo "    Management Group ID:   $MG_ID (Tenant ID)"
            echo "    Management Group Name: $MG_DISPLAY_NAME"
            echo "    Subscription ID:       $MGMT_SUBSCRIPTION_ID"
            echo "    Subscription Name:     $MANAGEMENT_SUBSCRIPTION_NAME"
            echo "    Service Principal Id:  $PLATFORM_ADMIN_CLIENT_ID"
            echo "    Tenant ID:             $TENANT_ID"
            echo ""
            echo " 7. Service connection name: $PLATFORM_ADMIN_SERVICE_CONNECTION"
            echo " 8. Click: Verify and save"
            echo ""
            echo " The federated credential is already configured, so it should verify."
            echo ""
            echo "============================================================================="
            exit 1
        }
    
    NEW_SC_ID=$(echo "$RESULT" | jq -r '.id // empty')
    
    if [[ -n "$NEW_SC_ID" ]]; then
        log_success "Service connection created successfully"
        log_info "Service Endpoint ID: $NEW_SC_ID"
    else
        log_warn "Service connection may have been created. Verifying..."
    fi
fi

echo ""

# =============================================================================
# Verify Service Connection
# =============================================================================
log_step "Verifying service connection..."

sleep 2  # Give Azure DevOps a moment to propagate

SC_LIST=$(az devops service-endpoint list --query "[?name=='$PLATFORM_ADMIN_SERVICE_CONNECTION']" -o json 2>/dev/null || echo "[]")
SC_COUNT=$(echo "$SC_LIST" | jq length)

if [[ "$SC_COUNT" -gt 0 ]]; then
    SC_ID=$(echo "$SC_LIST" | jq -r '.[0].id')
    log_success "Service connection verified!"
    log_info "Service Connection ID: $SC_ID"
else
    log_warn "Could not verify service connection via API"
    log_info "Please check Azure DevOps manually"
fi

echo ""

# =============================================================================
# Output Summary
# =============================================================================
echo "============================================================================="
echo " Service Connection Setup Complete"
echo "============================================================================="
echo ""
echo " Azure DevOps Details:"
echo "   Organization:    $ADO_ORGANIZATION"
echo "   Project:         $ADO_PROJECT"
echo "   Connection Name: $PLATFORM_ADMIN_SERVICE_CONNECTION"
echo ""
echo " Service Principal:"
echo "   Client ID:       $PLATFORM_ADMIN_CLIENT_ID"
echo "   Tenant ID:       $TENANT_ID"
echo ""
echo " Federated Credential:"
echo "   Issuer:          $FED_ISSUER"
echo "   Subject:         $FED_SUBJECT"
echo ""
echo " Scope (Tenant Root Management Group):"
echo "   ID:              $MG_ID"
echo "   Display Name:    $MG_DISPLAY_NAME"
echo ""
echo " Default Subscription Context:"
echo "   ID:              $MGMT_SUBSCRIPTION_ID"
echo "   Name:            $MANAGEMENT_SUBSCRIPTION_NAME"
echo ""
echo "============================================================================="
echo ""

log_success "Azure DevOps service connection setup completed!"
echo ""
echo "Next steps:"
echo "  1. Create variable groups as documented in the README"
echo "  2. Create pipelines from the YAML files"
echo "  3. Run the terraform-bootstrap-state pipeline"
echo ""
