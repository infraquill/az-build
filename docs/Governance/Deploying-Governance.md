# Deploying Governance

This guide walks you through deploying Azure Policy assignments for compliance and security governance.

## Prerequisites

Before deploying governance policies, ensure you have:

1. **Management Group Hierarchy**: The target management group must exist (deploy `mg-hierarchy-pipeline` first)
2. **Required Permissions**: 
   - Resource Policy Contributor role on the target management group
   - User Access Administrator role on the target management group (for managed identity role assignments)
3. **Azure CLI**: Installed and configured (for local deployment)
4. **Azure DevOps**: Access to the pipeline (for automated deployment)
5. **Service Connection**: Configured in Azure DevOps with appropriate permissions

## Configuration

### Step 1: Review Parameters File

The `governance.bicepparam` file contains the deployment configuration:

```bicep
using 'governance.bicep'

param location = 'canadacentral'
param environment = 'live'
param owner = 'platform-team'
param managedBy = 'Bicep'
param enforcementMode = 'DoNotEnforce'
param enableMCSB = true
param enableCanadaPBMM = true
```

### Step 2: Customize Parameters

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|--------------|
| `location` | Azure region for managed identity | `canadacentral` | Any valid Azure region |
| `environment` | Environment name | `live` | `nonprod`, `dev`, `test`, `uat`, `staging`, `prod`, `live` |
| `owner` | Owner tag value | - | Email or team name |
| `managedBy` | Management tool tag | `Bicep` | Any string |
| `enforcementMode` | Policy enforcement mode | `DoNotEnforce` | `DoNotEnforce`, `Default` |
| `enableMCSB` | Enable Microsoft Cloud Security Benchmark | `true` | `true`, `false` |
| `enableCanadaPBMM` | Enable Canada Federal PBMM | `true` | `true`, `false` |

## Deployment Methods

### Method 1: Azure DevOps Pipeline (Recommended)

The pipeline provides automated validation, what-if analysis, and deployment at management group scope.

#### Pipeline Stages

1. **Validate**: Validates the Bicep template and parameters
2. **What-If**: Shows what changes will be made before deployment
3. **Deploy**: Creates the policy assignments

#### Running the Pipeline

1. Navigate to Azure DevOps Pipelines
2. Select `governance-pipeline`
3. Click "Run pipeline"
4. Configure the pipeline parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| Management Group ID | Target management group for policy assignment | `mg-platform` |
| Environment | Target environment | `live` |
| Location Code | Short location code (e.g., `cac` for Canada Central) | `cac` |
| Location | Azure region | `canadacentral` |
| Owner | Resource owner | (from variable group) |
| Managed By | Management tool | (from variable group) |
| Enforcement Mode | `DoNotEnforce` (audit) or `Default` (enforce) | `DoNotEnforce` |
| Enable MCSB | Enable Microsoft Cloud Security Benchmark | `true` |
| Enable Canada PBMM | Enable Canada Federal PBMM | `true` |
| Deployment Stage | Which stage to run | `WhatIf` |

5. Select the **Deployment Stage**:
   - `Validation` - Only validates the template
   - `WhatIf` - Validates and shows what-if analysis
   - `Deploy` - Full deployment (requires approval)

6. Review the validation and what-if results
7. Approve the deployment when ready

#### Available Target Management Groups

The pipeline supports these management group targets:

| Management Group | Description |
|------------------|-------------|
| `$(azureTenantId)` | Tenant Root (entire tenant) |
| `mg-platform` | Platform management group |
| `mg-landing-zone` | Landing zone root |
| `mg-sandbox` | Sandbox subscriptions |
| `mg-decommissioned` | Decommissioned subscriptions |
| `mg-management` | Management subscriptions |
| `mg-connectivity` | Connectivity subscriptions |
| `mg-corp-prod` | Corporate production |
| `mg-corp-non-prod` | Corporate non-production |
| `mg-online-prod` | Online production |
| `mg-online-non-prod` | Online non-production |

#### Required Pipeline Variables

Configure these in your `common-variables` variable group:

| Variable | Description |
|----------|-------------|
| `azureServiceConnection` | Azure DevOps service connection name |
| `deploymentLocation` | Azure region for deployment metadata |
| `defaultOwner` | Default owner for tags |
| `managedBy` | Default managed-by value for tags |

### Method 2: Azure CLI (Local Deployment)

For local testing or manual deployment at management group scope.

#### Validate Template

```bash
az deployment mg validate \
  --management-group-id "mg-platform" \
  --location canadacentral \
  --template-file code/bicep/governance/governance.bicep \
  --parameters code/bicep/governance/governance.bicepparam \
  --parameters environment="live" \
  --parameters location="canadacentral" \
  --parameters owner="platform-team" \
  --parameters managedBy="Bicep" \
  --parameters enableMCSB=true \
  --parameters enableCanadaPBMM=true \
  --parameters enforcementMode="DoNotEnforce"
```

#### What-If Analysis

```bash
az deployment mg what-if \
  --management-group-id "mg-platform" \
  --location canadacentral \
  --template-file code/bicep/governance/governance.bicep \
  --parameters code/bicep/governance/governance.bicepparam \
  --parameters environment="live" \
  --parameters location="canadacentral" \
  --parameters owner="platform-team" \
  --parameters managedBy="Bicep" \
  --parameters enableMCSB=true \
  --parameters enableCanadaPBMM=true \
  --parameters enforcementMode="DoNotEnforce"
```

#### Deploy

```bash
az deployment mg create \
  --name "governance-live-cac-$(date +%Y%m%d%H%M%S)" \
  --management-group-id "mg-platform" \
  --location canadacentral \
  --template-file code/bicep/governance/governance.bicep \
  --parameters code/bicep/governance/governance.bicepparam \
  --parameters environment="live" \
  --parameters location="canadacentral" \
  --parameters owner="platform-team" \
  --parameters managedBy="Bicep" \
  --parameters enableMCSB=true \
  --parameters enableCanadaPBMM=true \
  --parameters enforcementMode="DoNotEnforce"
```

## Verification

After deployment, verify the policy assignments:

### Azure Portal

1. Navigate to **Azure Policy**
2. Select **Assignments** in the left menu
3. Filter by scope to your target management group
4. Verify the policy assignments exist:
   - `Microsoft Cloud Security Benchmark - Audit` (if enabled)
   - `Canada Federal PBMM - Audit` (if enabled)
5. Click on each assignment to verify configuration:
   - Enforcement mode is correct
   - Managed identity is assigned
   - Metadata tags are set

### Azure CLI

```bash
# List policy assignments at management group scope
az policy assignment list \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform" \
  --output table

# Get MCSB assignment details
az policy assignment show \
  --name "mcsb-audit-live" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform"

# Get Canada PBMM assignment details
az policy assignment show \
  --name "canada-pbmm-audit-live" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform"
```

### Deployment Outputs

The deployment provides these outputs:

| Output | Description |
|--------|-------------|
| `mcsbAssignmentId` | Resource ID of MCSB policy assignment |
| `mcsbAssignmentName` | Name of MCSB policy assignment |
| `mcsbPrincipalId` | Managed identity principal ID for MCSB |
| `canadaPbmmAssignmentId` | Resource ID of Canada PBMM policy assignment |
| `canadaPbmmAssignmentName` | Name of Canada PBMM policy assignment |
| `canadaPbmmPrincipalId` | Managed identity principal ID for Canada PBMM |

## Checking Compliance

After deployment, compliance evaluation begins automatically (may take up to 24 hours for initial scan):

### Azure Portal

1. Navigate to **Azure Policy**
2. Select **Compliance** in the left menu
3. Filter by scope to your target management group
4. Review compliance percentages for each initiative

### Azure CLI

```bash
# Trigger on-demand compliance scan
az policy state trigger-scan \
  --resource-group "<resource-group>" \
  --no-wait

# Get compliance summary
az policy state summarize \
  --management-group "mg-platform"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you have `Resource Policy Contributor` role on the target management group
   - Verify `User Access Administrator` role if managed identity needs role assignments
   - See [RBAC Requirements](../RBAC-Requirements.md) for detailed permissions

2. **Management Group Not Found**
   - Verify the management group ID is correct
   - Ensure the management group hierarchy is deployed first
   - Check you have permissions to view the management group

3. **Policy Definition Not Found**
   - The built-in policy initiatives should always be available
   - Verify the initiative IDs are correct
   - Check for any Azure outages

4. **Deployment Failed with "InvalidPolicyDefinitionReference"**
   - The policy initiative may have been updated or deprecated
   - Check Azure documentation for current initiative IDs
   - Update the Bicep template if initiative IDs have changed

5. **Managed Identity Not Created**
   - Verify `location` parameter is set (required for managed identity)
   - Check the `identity` property is set to `SystemAssigned` in the template

6. **Compliance Not Showing**
   - Initial compliance scan can take up to 24 hours
   - Trigger an on-demand scan using Azure CLI
   - Verify resources exist within the policy scope

### Viewing Deployment Logs

```bash
# List recent deployments at management group scope
az deployment mg list \
  --management-group-id "mg-platform" \
  --output table

# Get deployment details
az deployment mg show \
  --name "<deployment-name>" \
  --management-group-id "mg-platform"

# Get deployment operations for troubleshooting
az deployment mg operation list \
  --name "<deployment-name>" \
  --management-group-id "mg-platform"
```

## Next Steps

After deploying governance policies:

1. [Managing Governance](Managing-Governance.md) - Learn about ongoing management and compliance monitoring
2. Review compliance reports in Azure Policy
3. Identify non-compliant resources and create IaC tasks to remediate
4. Update Bicep templates to address compliance gaps
5. Set up Azure Monitor alerts for compliance state changes

> **Note:** Policies are designed to remain in audit mode. Use compliance data to identify gaps, then remediate through IaC pipelines—not through policy remediation tasks. This keeps all infrastructure changes centralized and traceable.
