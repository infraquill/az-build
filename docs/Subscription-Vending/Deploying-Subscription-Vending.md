# Deploying Subscription Vending

This guide walks you through deploying subscription vending to create new Azure subscriptions.

## Prerequisites

Before deploying subscription vending, ensure you have:

1. **Azure Tenant Access**: Access to the Azure tenant where subscriptions will be created
2. **Required Permissions**: 
   - Owner role at the Tenant Root Management Group (for subscription alias creation at tenant scope)
   - Subscription creation permissions (typically requires Enrollment Account permissions for EA or Billing Account permissions for MCA)
   - Management group write permissions
3. **Management Group**: The target management group must exist
4. **Billing Information**: Billing account details if using EA or MCA (optional for pay-as-you-go)
5. **Azure CLI**: Installed and configured (for local deployment)
6. **Azure DevOps**: Access to the pipeline (for automated deployment)
7. **Service Connection**: Configured in Azure DevOps with tenant-scope deployment permissions

## Configuration

### Step 1: Review Parameters File

The `sub-vending.bicepparam` file contains the deployment configuration:

```bicep
using 'sub-vending.bicep'

param managementGroupId = 'your-management-group-id'
param billingScope = ''
param workload = 'Production'
param workloadAlias = 'example-project'
param environment = 'dev'
param locationCode = 'cac'
param instanceNumber = '001'
param owner = 'example-owner'
param managedBy = 'Bicep'
param existingSubscriptionId = '' // Optional: provide to move an existing subscription
```

### Step 2: Customize Parameters

| Parameter | Description | Default | Required | Valid Values |
|-----------|-------------|---------|----------|--------------|
| `managementGroupId` | Management group ID where subscription will be placed | - | Yes | Valid management group ID |
| `billingScope` | Billing scope for EA/MCA scenarios | `''` | No | `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}` |
| `workload` | Workload type | `Production` | No | `Production`, `DevTest` |
| `workloadAlias` | Workload alias for naming conventions | - | Yes | Any alphanumeric string |
| `environment` | Environment identifier | - | Yes | `dev`, `test`, `uat`, `staging`, `prod`, `live`, `nonprod` |
| `locationCode` | Short location code | `cac` | No | `cac`, `cae`, `eus`, etc. |
| `instanceNumber` | Instance identifier | - | Yes | Three-digit string (e.g., `001`) |
| `owner` | Subscription owner | - | Yes | Email or team name |
| `managedBy` | Management tool | `Bicep` | No | Any string |
| `existingSubscriptionId` | Existing subscription ID to move (optional) | `''` | No | Subscription GUID |

> **Note**: The subscription display name is automatically generated from the naming convention: `subcr-<workloadAlias>-<environment>-<locationCode>-<instanceNumber>`

### Step 3: Understand Subscription Alias

The subscription alias is automatically generated from the parameters:

**Pattern**: `subcr-<workloadAlias>-<environment>-<locationCode>-<instanceNumber>`

**Example**: 
- Workload Alias: `hub`
- Environment: `live`
- Location Code: `cac`
- Instance Number: `001`
- **Result**: `subcr-hub-live-cac-001`

### Step 4: Determine Billing Scope (Optional)

For Enterprise Agreement (EA) or Microsoft Customer Agreement (MCA) scenarios:

1. **Get Billing Account ID**: 
   ```bash
   az billing account list --output table
   ```

2. **Get Invoice Section ID**:
   ```bash
   az billing invoice-section list \
     --account-name <billingAccountName> \
     --profile-name <billingProfileName> \
     --output table
   ```

3. **Construct Billing Scope**:
   ```
   /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}
   ```

For pay-as-you-go subscriptions, leave `billingScope` empty.

## Deployment Methods

### Method 1: Azure DevOps Pipeline (Recommended)

The pipeline provides automated validation, what-if analysis, and deployment at the tenant scope.

#### Pipeline Stages

1. **Validate**: Validates the Bicep template and parameters
2. **What-If**: Shows what changes will be made before deployment
3. **Deploy**: Creates the subscription

#### Running the Pipeline

1. Navigate to Azure DevOps Pipelines
2. Select `sub-vending-pipeline`
3. Click "Run pipeline"
4. Configure the pipeline parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| Workload Alias | Workload alias for naming | `hub` |
| Environment | Target environment | `live` |
| Location Code | Short location code | `cac` |
| Instance Number | Instance identifier | `001` |
| Management Group ID | Target management group | `mg-connectivity` |
| Billing Scope (optional) | Billing scope for EA/MCA | `/providers/Microsoft.Billing/...` |
| Workload Type | Production or DevTest | `Production` |
| Owner | Subscription owner | `platform-team@organization.com` |
| Managed By | Management tool | `Bicep` |
| Existing Subscription ID (optional) | Move existing subscription | Subscription GUID |
| Pipeline Stage to Run | Which stage to run | `WhatIf` or `Deploy` |

5. Review the validation and what-if results
6. Approve the deployment in the `subscription-vending` environment

#### Required Pipeline Variables

Configure these in your `common-variables` variable group:

| Variable | Description |
|----------|-------------|
| `azureServiceConnection` | Azure DevOps service connection name |
| `azureTenantId` | Azure tenant ID |
| `deploymentLocation` | Azure region for deployment metadata |

### Method 2: Azure CLI (Local Deployment)

For local testing or manual deployment at the tenant scope.

#### Validate Template

```bash
az deployment tenant validate \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters code/bicep/sub-vending/sub-vending.bicepparam \
  --parameters managementGroupId='mg-connectivity' \
  --parameters workloadAlias='hub' \
  --parameters environment='live' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com'
```

#### What-If Analysis

```bash
az deployment tenant what-if \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters code/bicep/sub-vending/sub-vending.bicepparam \
  --parameters managementGroupId='mg-connectivity' \
  --parameters workloadAlias='hub' \
  --parameters environment='live' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com'
```

#### Deploy

```bash
az deployment tenant create \
  --name 'sub-vending-hub-live-cac-001' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters code/bicep/sub-vending/sub-vending.bicepparam \
  --parameters managementGroupId='mg-connectivity' \
  --parameters workloadAlias='hub' \
  --parameters environment='live' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com'
```

#### Deploy with Billing Scope (EA/MCA)

```bash
az deployment tenant create \
  --name 'sub-vending-hub-live-cac-001' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters code/bicep/sub-vending/sub-vending.bicepparam \
  --parameters managementGroupId='mg-connectivity' \
  --parameters billingScope='/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}' \
  --parameters workloadAlias='hub' \
  --parameters environment='live' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com'
```

#### Move Existing Subscription

```bash
az deployment tenant create \
  --name 'sub-vending-move-existing' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters code/bicep/sub-vending/sub-vending.bicepparam \
  --parameters managementGroupId='mg-connectivity' \
  --parameters workloadAlias='hub' \
  --parameters environment='live' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com' \
  --parameters existingSubscriptionId='00000000-0000-0000-0000-000000000000'
```

## Verification

After deployment, verify the subscription was created correctly:

### Azure Portal

1. Navigate to **Subscriptions** in the Azure Portal
2. Search for the subscription by display name or alias
3. Verify the subscription details:
   - Display name matches
   - Management group assignment is correct
   - Tags are applied correctly
   - Workload type is set correctly
   - Billing scope (if specified) is correct

### Azure CLI

```bash
# Get subscription details
az account show \
  --subscription <subscription-id> \
  --output json

# List subscriptions in a management group
az account management-group subscription show \
  --name <management-group-id> \
  --subscription <subscription-id>

# Check subscription tags
az account show \
  --subscription <subscription-id> \
  --query tags \
  --output json

# Verify subscription alias
az account alias list \
  --output table
```

### Deployment Outputs

The deployment provides these outputs:

| Output | Description |
|--------|-------------|
| `subscriptionAliasName` | The subscription alias name following the naming convention |
| `subscriptionId` | The subscription ID (GUID) |
| `managementGroupResourceId` | The full resource ID of the target management group |
| `isExistingSubscription` | Boolean indicating if an existing subscription was moved |

**Retrieve outputs from Azure CLI:**

```bash
az deployment tenant show \
  --name 'sub-vending-hub-live-cac-001' \
  --query properties.outputs \
  --output json
```

## Common Deployment Scenarios

### Scenario 1: Production Hub Subscription

Create a production subscription for hub infrastructure:

```bash
az deployment tenant create \
  --name 'sub-vending-hub-prod-cac-001' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters managementGroupId='mg-connectivity' \
  --parameters workloadAlias='hub' \
  --parameters environment='prod' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters workload='Production' \
  --parameters owner='platform-team@organization.com'
```

### Scenario 2: DevTest Development Subscription

Create a DevTest subscription for development workloads:

```bash
az deployment tenant create \
  --name 'sub-vending-app-dev-cac-001' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters managementGroupId='mg-online-non-prod' \
  --parameters workloadAlias='app-dev' \
  --parameters environment='dev' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters workload='DevTest' \
  --parameters owner='dev-team@organization.com'
```

### Scenario 3: Subscription with Billing Scope

Create a subscription with EA/MCA billing scope:

```bash
az deployment tenant create \
  --name 'sub-vending-monitoring-prod-cac-001' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters managementGroupId='mg-management' \
  --parameters billingScope='/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}' \
  --parameters workloadAlias='monitoring' \
  --parameters environment='prod' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters workload='Production' \
  --parameters owner='ops-team@organization.com'
```

### Scenario 4: Move Existing Subscription

Move an existing subscription to a management group:

```bash
az deployment tenant create \
  --name 'sub-vending-move-existing' \
  --location canadacentral \
  --template-file code/bicep/sub-vending/sub-vending.bicep \
  --parameters managementGroupId='mg-landing-zone' \
  --parameters workloadAlias='existing-app' \
  --parameters environment='prod' \
  --parameters locationCode='cac' \
  --parameters instanceNumber='001' \
  --parameters owner='platform-team@organization.com' \
  --parameters existingSubscriptionId='00000000-0000-0000-0000-000000000000'
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you have Owner role at the Tenant Root Management Group (required for tenant scope deployments)
   - Check you have subscription creation permissions
   - Verify the service connection has tenant-scope deployment permissions
   - For EA: Ensure you have Enrollment Account permissions
   - For MCA: Ensure you have Billing Account permissions

2. **Management Group Not Found**
   - Verify the management group ID exists
   - Ensure you have permissions to the management group
   - Check the management group hierarchy is deployed

3. **Subscription Alias Already Exists**
   - The subscription alias must be unique
   - Change the instance number or use a different workloadAlias/environment combination
   - Check for existing subscriptions with the same alias

4. **Invalid Billing Scope**
   - Verify the billing account ID is correct
   - Ensure the invoice section ID is valid
   - Check you have permissions to the billing account
   - Verify the billing scope format is correct

5. **Subscription Creation Failed**
   - Check subscription limits for your tenant
   - Verify billing account has available subscription quota
   - Ensure all required parameters are provided
   - Check Azure service health for subscription creation issues

6. **Deployment Timeout**
   - Subscription creation can take several minutes
   - Wait for the deployment to complete
   - Check the deployment status in Azure Portal

7. **Invalid Parameter Values**
   - Verify environment values match allowed values
   - Check workload type is `Production` or `DevTest`
   - Ensure instance number is three digits
   - Validate location code format

8. **Tag Application Failed**
   - Tags are applied during subscription creation
   - Verify tag values don't contain invalid characters
   - Check tag limits (50 tags per subscription)

## Next Steps

After creating a subscription:

1. [Managing Subscription Vending](Managing-Subscription-Vending.md) - Learn about ongoing management
2. Verify the subscription appears in the correct management group
3. Confirm policies are applied from the management group
4. Set up cost management and budgets
5. Configure access control (RBAC) for the subscription
6. Deploy infrastructure to the new subscription
