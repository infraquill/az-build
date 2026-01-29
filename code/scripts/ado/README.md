# Azure DevOps Scripts

This directory contains scripts for managing Azure DevOps resources, including service principals, service connections, variable groups, and deployment environments required by the infrastructure deployment pipelines.

## Quick Start

```bash
# 1. Create your configuration file
cp config.sh.example config.sh

# 2. Edit config.sh with your values
# Required values:
#   - AAD_TENANT_ID: Your Azure AD tenant ID
#   - ADO_PAT_TOKEN: Personal Access Token with required permissions
#   - ADO_ORGANIZATION_URL: e.g., https://dev.azure.com/myorg
#   - ADO_PROJECT_NAME: Your Azure DevOps project name
#   - PLATFORM_ADMIN_SP_NAME: Service principal name (e.g., sp-landing-zone-admin)

# 3. Verify prerequisites
bash check-prerequisites.sh

# 4. Run complete ADO setup
bash setup-ado.sh
```

## What `setup-ado.sh` Does

The master setup script runs the following in sequence:

1. **`create-platform-admin.sh`** - Creates the Platform Admin service principal with required Azure RBAC and Entra ID roles
2. **`create-variable-groups.sh`** - Creates all Azure DevOps variable groups for pipeline configuration
3. **`create-environments.sh`** - Creates Azure DevOps deployment environments

## Scripts

| Script | Description |
|--------|-------------|
| `setup-ado.sh` | **Master script** - Complete ADO setup (service principal + variable groups + environments) |
| `check-prerequisites.sh` | Verifies all prerequisites are met (CLI tools, extensions, config) |
| `create-platform-admin.sh` | Creates Platform Admin service principal with Azure RBAC and Entra ID roles |
| `create-service-connection.sh` | Creates Azure DevOps service connection with Workload Identity Federation |
| `create-variable-groups.sh` | Orchestrates creation of all variable groups |
| `create-environments.sh` | Creates Azure DevOps deployment environments |
| `create-common-variables.sh` | Creates/updates the `common-variables` variable group |
| `create-mg-hierarchy-variables.sh` | Creates/updates the `mg-hierarchy-variables` variable group |
| `create-monitoring-variables.sh` | Creates/updates the `monitoring-variables` variable group |
| `create-governance-variables.sh` | Creates/updates the `governance-variables` variable group |
| `create-hub-variables.sh` | Creates/updates the `hub-variables` variable group |
| `delete-variable-groups.sh` | Deletes variable groups (use with caution!) |
| `show-variable-groups.sh` | Displays details of existing variable groups |
| `lib.sh` | Shared library functions (variable groups + environments) |
| `config.sh` | Your configuration (gitignored - create from example) |
| `config.sh.example` | Configuration template with documentation |

## Platform Admin Service Principal

The `create-platform-admin.sh` script creates a service principal with the following permissions:

### Azure RBAC Roles
- **Owner** on Tenant Root Management Group (full hierarchy access)
- **Owner** on Management Subscription (if exists)
- **Owner** on Connectivity Subscription (if exists)

### Microsoft Entra ID Roles
- **Application Administrator** - Required for creating app registrations during subscription vending

### Billing Permissions (Manual)
- **Billing Account Contributor/Owner** - Required for automatic subscription creation (optional, can use pre-created subscriptions instead)

## Service Connection

The `create-service-connection.sh` script creates an Azure DevOps service connection using **Workload Identity Federation** for passwordless authentication. The connection is scoped to the Tenant Root Management Group for full hierarchy access.

**Prerequisites:**
- Run `create-platform-admin.sh` first to create the service principal
- The script will automatically create the federated credential on the app registration

## Variable Groups Created

### `common-variables`

Used by **all** infrastructure deployment pipelines:

| Variable | Description | Source |
|----------|-------------|--------|
| `azureServiceConnection` | Name of the Azure service connection | `AZURE_SERVICE_CONNECTION_NAME` |
| `deploymentLocation` | Default Azure region for deployments | `DEPLOYMENT_LOCATION` |
| `azureTenantId` | Azure AD tenant ID | `AAD_TENANT_ID` |
| `locationCode` | Default location code for naming (e.g., "cac") | `DEFAULT_LOCATION_CODE` |
| `defaultOwner` | Default owner contact for resources | `DEFAULT_OWNER` |
| `managedBy` | Infrastructure management tool (e.g., "Bicep") | `MANAGED_BY` |
| `denySettingsMode` | Default deployment stack deny settings | `DEFAULT_DENY_SETTINGS_MODE` |
| `actionOnUnmanage` | Default action on unmanaged resources | `DEFAULT_ACTION_ON_UNMANAGE` |
| `billingAccountId` | Billing Account ID for subscription vending | `BILLING_ACCOUNT_ID` |
| `billingProfileId` | Billing Profile ID (for reference) | `BILLING_PROFILE_ID` |
| `invoiceSectionId` | Invoice Section ID for MCA billing | `INVOICE_SECTION_ID` |
| `enrollmentAccountId` | Enrollment Account ID for EA billing | `ENROLLMENT_ACCOUNT_ID` |
| `environments` | Comma-separated list of valid environments | `ENVIRONMENTS` array |

### `mg-hierarchy-variables`

Used by the management group hierarchy pipeline:

| Variable | Description | Source |
|----------|-------------|--------|
| `orgName` | Organization name used for management group IDs (e.g., "contoso" → "mg-contoso") | `ORG_NAME` |
| `orgDisplayName` | Organization display name shown in Azure Portal | `ORG_DISPLAY_NAME` |

### `monitoring-variables`

Used by the monitoring infrastructure pipeline. Contains only STRING values that may need organization-wide updates:

| Variable | Description | Source |
|----------|-------------|--------|
| `monitoringSubscriptionId` | Subscription ID for monitoring resources | `MONITORING_SUBSCRIPTION_ID` |
| `actionGroupEmails` | Comma-separated email addresses for alert notifications | `ACTION_GROUP_EMAILS` |
| `actionGroupSmsNumbers` | Comma-separated SMS numbers (format: "countryCode:phone") | `ACTION_GROUP_SMS_NUMBERS` |

> **Note:** Stable configuration (SKU, data retention, thresholds, security settings) is defined in `monitoring.bicepparam`, not in variable groups. ADO variable groups only support strings.

### `governance-variables`

Used by the governance compliance policies pipeline. Currently a placeholder for future extensibility:

| Variable | Description | Source |
|----------|-------------|--------|
| (none) | Pipeline uses parameters for `enableMCSB` and `enableCanadaPBMM` | — |

### `hub-variables`

Used by the hub infrastructure deployment pipeline. Contains only STRING values:

| Variable | Description | Source |
|----------|-------------|--------|
| `hubSubscriptionId` | Subscription ID for hub/connectivity resources | `HUB_SUBSCRIPTION_ID` |
| `logAnalyticsWorkspaceResourceId` | Resource ID of Log Analytics Workspace from monitoring | `LOG_ANALYTICS_WORKSPACE_RESOURCE_ID` |
| `privateDnsZoneName` | Organization-wide private DNS zone name | `PRIVATE_DNS_ZONE_NAME` |
| `avnmManagementGroupId` | Management group ID for AVNM scope | `AVNM_MANAGEMENT_GROUP_ID` |
| `keyVaultAdminPrincipalId` | Object ID for Key Vault Administrator role (optional) | `KEY_VAULT_ADMIN_PRINCIPAL_ID` |

> **Note:** Stable configuration (VNet address space, IPAM pool settings) is defined in `hub.bicepparam`, not in variable groups.

## Deployment Environments

The `create-environments.sh` script creates Azure DevOps environments used by pipeline deployment jobs. Environments are configured via the `ENVIRONMENTS` array in `config.sh`:

```bash
# Default environments (in config.sh)
ENVIRONMENTS=("nonprod" "dev" "test" "uat" "staging" "prod" "live")
```

### Environment Validation in Pipelines

Pipelines validate the `environment` parameter at runtime against the `environments` variable stored in the `common-variables` group. This ensures:

- The environment parameter matches the authoritative list
- Early failure with clear error messages if invalid
- Consistency between YAML dropdown values and allowed environments

### Customizing Environments

To customize the environments list:

1. Edit `config.sh` and modify the `ENVIRONMENTS` array
2. Run `bash setup-ado.sh` to update the variable group and create environments
3. Update the `values:` list in pipeline YAML files (for the UI dropdown)

## Prerequisites

### Required Tools

1. **Azure CLI** (v2.50.0+)
   ```bash
   # macOS
   brew install azure-cli
   
   # Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Verify
   az --version
   ```

2. **Azure DevOps CLI Extension**
   ```bash
   az extension add --name azure-devops
   
   # Verify
   az extension show --name azure-devops
   ```

3. **jq** (for JSON processing)
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   ```

### Azure DevOps PAT Token

Create a Personal Access Token at:
`https://dev.azure.com/{organization}/_usersSettings/tokens`

**Required permissions** (all are necessary for `setup-ado.sh` to work):

| Scope | Permission | Location in PAT UI |
|-------|------------|-------------------|
| Variable Groups | Read & Manage | Pipelines → Variable Groups |
| Environment | Read & Manage | Pipelines → Environment |
| Project and Team | Read | Project → Read |

**Optional permissions** (for additional automation):

| Scope | Permission | Purpose |
|-------|------------|---------|
| Build | Read & Execute | Trigger/manage pipelines |
| Service Connections | Read, Query, & Manage | Create/manage service connections |

> **Tip**: When creating the PAT, expand the "Pipelines" section to find both "Variable Groups" and "Environment" permissions.

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AAD_TENANT_ID` | Azure AD tenant ID (GUID) | `12345678-1234-1234-1234-123456789012` |
| `ADO_PAT_TOKEN` | Personal Access Token | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `ADO_ORGANIZATION_URL` | Azure DevOps org URL | `https://dev.azure.com/myorg` |
| `ADO_PROJECT_NAME` | Project name | `MyProject` |
| `PLATFORM_ADMIN_SP_NAME` | Service principal name | `sp-landing-zone-admin` |

### Azure Billing Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `BILLING_ACCOUNT_ID` | Billing Account ID (for subscription vending) | (empty) |
| `BILLING_PROFILE_ID` | Billing Profile ID (optional reference) | (empty) |
| `INVOICE_SECTION_ID` | Invoice Section ID for MCA billing | (empty) |
| `ENROLLMENT_ACCOUNT_ID` | Enrollment Account ID for EA billing | (empty) |

> **Note:** For MCA billing, provide `INVOICE_SECTION_ID`. For EA billing, provide `ENROLLMENT_ACCOUNT_ID`. Only one should be set.

### Subscription Names

| Variable | Description | Default |
|----------|-------------|---------|
| `MANAGEMENT_SUBSCRIPTION_NAME` | Management subscription name | (empty) |
| `CONNECTIVITY_SUBSCRIPTION_NAME` | Connectivity/Hub subscription name | (empty) |

### Common Variables Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_SERVICE_CONNECTION_NAME` | Service connection name | `azure-infra-connection` |
| `DEPLOYMENT_LOCATION` | Default Azure region | `canadacentral` |
| `DEFAULT_LOCATION_CODE` | Default location code for naming | `cac` |
| `DEFAULT_OWNER` | Default owner contact for resources | (empty) |
| `MANAGED_BY` | Infrastructure management tool | `Bicep` |
| `DEFAULT_DENY_SETTINGS_MODE` | Deployment stack deny settings | `denyWriteAndDelete` |
| `DEFAULT_ACTION_ON_UNMANAGE` | Action on unmanaged resources | `detachAll` |

### Management Group Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `ROOT_MG_NAME` | Root management group name | `mg-organization` |
| `ROOT_MG_DISPLAY_NAME` | Root management group display name | `Organization Root` |
| `ORG_NAME` | Organization name for management group IDs | `org` |
| `ORG_DISPLAY_NAME` | Organization display name | `Organization Name` |

### Monitoring Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `MONITORING_SUBSCRIPTION_ID` | Monitoring subscription ID | (empty) |
| `ACTION_GROUP_EMAILS` | Comma-separated email addresses | (empty) |
| `ACTION_GROUP_SMS_NUMBERS` | SMS numbers (format: countryCode:phone) | (empty) |

### Hub Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `HUB_SUBSCRIPTION_ID` | Hub/Connectivity subscription ID | (empty) |
| `LOG_ANALYTICS_WORKSPACE_RESOURCE_ID` | Log Analytics Workspace Resource ID | (empty) |
| `PRIVATE_DNS_ZONE_NAME` | Organization private DNS zone name | `internal.organization.com` |
| `AVNM_MANAGEMENT_GROUP_ID` | Management group ID for AVNM | `mg-connectivity` |
| `KEY_VAULT_ADMIN_PRINCIPAL_ID` | Object ID for Key Vault admin (optional) | (empty) |

### Environment Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENTS` | Array of deployment environments | `("nonprod" "dev" "test" "uat" "staging" "prod" "live")` |

## Usage Examples

### Complete ADO Setup (Recommended)
```bash
# Run full setup (service principal + variable groups + environments)
bash setup-ado.sh

# Dry run to see what would be done
bash setup-ado.sh --dry-run
```

### Check Prerequisites
```bash
bash check-prerequisites.sh
```

### Create Platform Admin Service Principal Only
```bash
bash create-platform-admin.sh
```

### Create Service Connection Only
```bash
# Requires create-platform-admin.sh to be run first
bash create-service-connection.sh
```

### Create Variable Groups Only
```bash
bash create-variable-groups.sh

# Dry run
bash create-variable-groups.sh --dry-run
```

### Create Environments Only
```bash
bash create-environments.sh

# Dry run
bash create-environments.sh --dry-run

# List existing environments
bash create-environments.sh --list
```

### List Existing Variable Groups
```bash
bash create-variable-groups.sh --list
# or
bash show-variable-groups.sh --list
```

### Show Variable Group Details
```bash
bash show-variable-groups.sh common-variables
# or show all
bash show-variable-groups.sh --all
```

### Delete Variable Groups
```bash
# Delete specific group
bash delete-variable-groups.sh common-variables

# Delete all managed groups
bash delete-variable-groups.sh --all

# Force delete without confirmation
bash delete-variable-groups.sh --all --force
```

## Pipelines Using These Variable Groups

All infrastructure pipelines in `/code/pipelines/` reference these variable groups:

| Pipeline | Variable Groups Used |
|----------|---------------------|
| `hub-pipeline.yaml` | `common-variables`, `hub-variables` |
| `spoke-networking-pipeline.yaml` | `common-variables` |
| `governance-pipeline.yaml` | `common-variables`, `governance-variables` |
| `mg-hierarchy-pipeline.yaml` | `common-variables`, `mg-hierarchy-variables` |
| `monitoring-pipeline.yaml` | `common-variables`, `monitoring-variables` |
| `sub-vending-pipeline.yaml` | `common-variables` |
| `cloudops-pipeline.yaml` | `common-variables` |
| `cloudops-devcenter-pipeline.yaml` | `common-variables` |

## Generated Files

The scripts generate the following files (all gitignored):

| File | Description |
|------|-------------|
| `.platform-admin-sp.env` | Service principal details (Client ID, Object IDs, Tenant ID) |
| `.bootstrap-context.env` | Bootstrap subscription context for subsequent scripts |

## Troubleshooting

### "Azure DevOps extension is not installed"
```bash
az extension add --name azure-devops
```

### "Failed to connect to Azure DevOps"
1. Verify your PAT token hasn't expired
2. Check the organization URL is correct
3. Ensure the PAT has required permissions

### "Variable group not found"
The group may not exist yet. Run:
```bash
bash create-variable-groups.sh
```

### "Environment could not be found"
The environment may not exist yet. Run:
```bash
bash create-environments.sh
```

### "Access denied" or "Failed to create environment"
Your PAT needs these permissions (all under "Pipelines" in the PAT creation UI):
- **Variable Groups**: Read & Manage
- **Environment**: Read & Manage

Also required (under "Project"):
- **Project and Team**: Read

Regenerate your PAT with these permissions and update `config.sh`.

### "Cannot access Tenant Root Management Group"
You may need to enable elevated access:
1. Go to Azure Portal > Microsoft Entra ID > Properties
2. Set "Access management for Azure resources" to **Yes**
3. Re-run the script

### "Could not assign Application Administrator role"
This role requires specific permissions to assign via API. If automatic assignment fails:
1. Go to Azure Portal > Microsoft Entra ID > Roles and administrators
2. Search for "Application Administrator"
3. Add assignment for your service principal

## Security Notes

- `config.sh` is gitignored and should **never** be committed
- `.platform-admin-sp.env` contains sensitive IDs and is gitignored
- PAT tokens should be rotated regularly (90-180 days recommended)
- Consider using Azure Key Vault for production secrets
- The scripts mask sensitive values in output where possible
- Use the minimum required PAT permissions