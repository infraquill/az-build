# Deploying Monitoring Infrastructure

This guide walks you through deploying the centralized monitoring infrastructure.

## Prerequisites

Before deploying the monitoring infrastructure, ensure you have:

1. **Azure Subscription**: A dedicated monitoring subscription (recommended)
2. **Required Permissions**: 
   - Owner or Contributor role on the target subscription
   - Or a custom role with resource group and Log Analytics permissions
3. **Azure CLI**: Installed and configured (for local deployment)
4. **Azure DevOps**: Access to the pipeline (for automated deployment)
5. **Service Connection**: Configured in Azure DevOps with appropriate permissions

## Configuration

### Step 1: Review Parameters File

The `monitoring.bicepparam` file contains the deployment configuration:

```bicep
using 'monitoring.bicep'

param workloadAlias = 'monitoring'
param environment = 'live'
param locationCode = 'cac'
param instanceNumber = '001'
param location = 'canadacentral'
param dataRetention = 60
param owner = 'platform-team'
param managedBy = 'Bicep'
```

### Step 2: Customize Parameters

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|--------------|
| `workloadAlias` | Workload alias for naming | `monitoring` | Any alphanumeric string |
| `environment` | Environment name | `live` | `nonprod`, `dev`, `test`, `uat`, `staging`, `prod`, `live` |
| `locationCode` | Short location code | `cac` | `cac`, `cae`, `eus`, etc. |
| `instanceNumber` | Instance identifier | `001` | Three-digit string |
| `location` | Azure region | `canadacentral` | Any valid Azure region |
| `dataRetention` | Log retention in days | `60` | 30-730 |
| `owner` | Owner tag value | - | Email or team name |
| `managedBy` | Management tool tag | `Bicep` | Any string |

## Deployment Methods

### Method 1: Azure DevOps Pipeline (Recommended)

The pipeline provides automated validation, what-if analysis, and deployment using Deployment Stacks.

#### Pipeline Stages

1. **Validate**: Validates the Bicep template and parameters
2. **What-If**: Shows what changes will be made before deployment
3. **Deploy**: Creates the monitoring infrastructure as a Deployment Stack

#### Running the Pipeline

1. Navigate to Azure DevOps Pipelines
2. Select `monitoring-pipeline`
3. Click "Run pipeline"
4. Configure the pipeline parameters:

| Parameter | Description |
|-----------|-------------|
| Monitoring Subscription ID | Target subscription for deployment |
| Workload Alias | Workload alias for naming (default: `monitoring`) |
| Environment | Target environment |
| Location Code | Short location code |
| Instance Number | Instance identifier |
| Location | Azure region |
| Data Retention | Retention period in days |
| Owner | Resource owner |
| Managed By | Management tool |
| Deny Settings Mode | Protection level (`none`, `denyDelete`, `denyWriteAndDelete`) |
| Action on Unmanage | What happens to unmanaged resources |
| Deployment Stage | Which stage to run (`Validation`, `WhatIf`, `Deploy`) |

5. Review the validation and what-if results
6. Approve the deployment in the `monitoring` environment

#### Required Pipeline Variables

Configure these in your `common-variables` variable group:

| Variable | Description |
|----------|-------------|
| `azureServiceConnection` | Azure DevOps service connection name |
| `deploymentLocation` | Azure region for deployment metadata |

### Method 2: Azure CLI (Local Deployment)

For local testing or manual deployment using Deployment Stacks.

#### Validate Template

```bash
az stack sub validate \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/monitoring/monitoring.bicep \
  --parameters code/bicep/monitoring/monitoring.bicepparam \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll
```

#### What-If Analysis

```bash
az stack sub create \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/monitoring/monitoring.bicep \
  --parameters code/bicep/monitoring/monitoring.bicepparam \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll \
  --what-if
```

#### Deploy

```bash
az stack sub create \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/monitoring/monitoring.bicep \
  --parameters code/bicep/monitoring/monitoring.bicepparam \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll \
  --yes
```

## Deployment Stack Options

### Deny Settings Mode

Controls what operations are denied on managed resources:

| Mode | Description |
|------|-------------|
| `none` | No restrictions |
| `denyDelete` | Prevents deletion of managed resources |
| `denyWriteAndDelete` | Prevents modification and deletion (recommended) |

### Action on Unmanage

Controls what happens when resources are removed from the template:

| Action | Description |
|--------|-------------|
| `deleteResources` | Deletes removed resources |
| `deleteAll` | Deletes removed resources and resource groups |
| `detachAll` | Detaches resources (keeps them but stops managing) |

## Verification

After deployment, verify the infrastructure:

### Azure Portal

1. Navigate to the target subscription
2. Verify the resource group exists: `rg-monitoring-<env>-<loc>-<instance>`
3. Open the resource group and verify the Log Analytics workspace
4. Check the workspace settings and retention configuration

### Azure CLI

```bash
# Check the deployment stack
az stack sub show \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>"

# List resources in the resource group
az resource list \
  --resource-group "rg-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --output table

# Get workspace details
az monitor log-analytics workspace show \
  --workspace-name "law-monitoring-live-cac-001" \
  --resource-group "rg-monitoring-live-cac-001" \
  --subscription "<subscription-id>"
```

### Deployment Outputs

The deployment provides these outputs:

| Output | Description |
|--------|-------------|
| `workspaceResourceId` | Full resource ID of the Log Analytics workspace |
| `workspaceName` | Name of the Log Analytics workspace |
| `resourceGroupName` | Name of the resource group |

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you have Owner or Contributor role on the subscription
   - Check the service connection has appropriate permissions

2. **Invalid Subscription**
   - Verify the subscription ID is correct
   - Ensure the subscription is active and accessible

3. **Name Already Exists**
   - Resource group or workspace name may already exist
   - Change the instance number or use a different workloadAlias

4. **Deployment Stack Conflict**
   - A stack with the same name may already exist
   - Delete the existing stack or use a different name

5. **Deny Settings Blocking Changes**
   - If updating, the deny settings may block modifications
   - Temporarily change deny settings mode to `none` if needed

## Next Steps

After deploying the monitoring infrastructure:

1. [Managing Monitoring Infrastructure](Managing-Monitoring-Infrastructure.md) - Learn about ongoing management
2. Configure diagnostic settings on Azure resources to send logs to the workspace
3. Create alerts and workbooks for monitoring
4. Consider onboarding to Azure Sentinel for security monitoring
