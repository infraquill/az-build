# Deploying CloudOps Infrastructure

This guide covers the four-stage deployment process for provisioning the CloudOps workload with Managed DevOps Pools.

## Prerequisites

Before deploying CloudOps infrastructure, ensure you have:

1. **Hub Infrastructure Deployed**
   - Hub VNet with AVNM configured
   - Private DNS Zone created

2. **Monitoring Infrastructure Deployed**
   - Log Analytics Workspace available
   - Resource ID noted for diagnostic settings

3. **Required Information**
   - Hub subscription ID
   - Hub resource group name
   - Hub Private DNS Zone name and resource ID

4. **Azure DevOps Configuration**
   - Service connection with appropriate permissions
   - Variable group `common-variables` configured
   - Pipeline environments created
   - **Administrator permissions** in Azure DevOps organization

5. **Resource Provider Registration**
   ```bash
   az provider register --namespace Microsoft.DevOpsInfrastructure
   az provider register --namespace Microsoft.DevCenter
   ```

## Stage 1: Create CloudOps Subscription

Use the subscription vending pipeline to create the CloudOps subscription.

### Pipeline Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionDisplayName` | Display name for the subscription | `CloudOps Production` |
| `workloadAlias` | Workload alias for naming | `cloudops` |
| `environment` | Environment type | `live` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `managementGroupId` | Target management group | `mg-corp-prod` |
| `workload` | Workload type | `Production` |
| `owner` | Owner email/group | `platform-team@organization.com` |

### Running the Pipeline

1. Navigate to **Pipelines** > **sub-vending-pipeline**
2. Click **Run pipeline**
3. Fill in the required parameters
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output
6. Re-run with `deploymentStage: Deploy` to create the subscription

### Outputs

After deployment, note the subscription ID from the pipeline output:
- `subscriptionId`: The new subscription's ID (needed for subsequent stages)

## Stage 2: Deploy CloudOps Spoke Networking

Use the spoke networking pipeline to deploy VNet and connect to hub.

### Pipeline Parameters

#### Core Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionId` | CloudOps subscription ID (from Stage 1) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `workloadAlias` | Workload alias for naming (match Stage 1) | `cloudops` |
| `environment` | Environment type (match Stage 1) | `live` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `location` | Azure region | `canadacentral` |

#### Network Configuration

| Parameter | Description | Example |
|-----------|-------------|---------|
| `spokeVnetAddressSpace` | VNet address space | `10.100.0.0/16` |

#### Hub References

| Parameter | Description | Example |
|-----------|-------------|---------|
| `hubPrivateDnsZoneName` | Private DNS Zone name | `internal.organization.com` |
| `hubPrivateDnsZoneResourceId` | Private DNS Zone resource ID | `/subscriptions/.../privateDnsZones/...` |
| `hubResourceGroupName` | Hub resource group | `rg-hub-live-cac-001` |
| `hubSubscriptionId` | Hub subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

#### Monitoring

| Parameter | Description | Example |
|-----------|-------------|---------|
| `logAnalyticsWorkspaceResourceId` | Log Analytics Workspace ID | `/subscriptions/.../workspaces/...` |
| `owner` | Owner email/group | `platform-team@organization.com` |

### Custom Subnet Configuration

For CloudOps, configure a subnet for the Managed DevOps Pool agents:

```bicep
param customSubnets = [
  {
    name: 'agents'
    addressPrefix: '10.100.0.0/24'
  }
  {
    name: 'management'
    addressPrefix: '10.100.1.0/24'
  }
]
```

### Running the Pipeline

1. Navigate to **Pipelines** > **spoke-networking-pipeline**
2. Click **Run pipeline**
3. Fill in all required parameters using CloudOps subscription from Stage 1
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output
6. Re-run with `deploymentStage: Deploy` to deploy

### Outputs

Note these values from the deployment outputs (needed for subsequent stages):
- `spokeVnetResourceId`: The VNet resource ID
- `spokeVnetSubnetResourceIds`: Array of subnet resource IDs

## Stage 3: Deploy DevCenter Infrastructure

Use the DevCenter pipeline to deploy DevCenter and Network Connection.

> **Note**: DevCenter is typically deployed once per organization and shared across multiple pools.

### Pipeline Parameters

#### Core Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionId` | CloudOps subscription ID (from Stage 1) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `workloadAlias` | Workload alias for naming | `devcenter` |
| `environment` | Environment type | `live` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `location` | Azure region | `canadacentral` |

#### Network Configuration

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subnetResourceId` | Subnet for Network Connection (from Stage 2) | `/subscriptions/.../subnets/agents` |

#### Monitoring

| Parameter | Description | Example |
|-----------|-------------|---------|
| `logAnalyticsWorkspaceResourceId` | Log Analytics Workspace ID | `/subscriptions/.../workspaces/...` |
| `owner` | Owner email/group | `platform-team@organization.com` |

### Running the Pipeline

1. Navigate to **Pipelines** > **cloudops-devcenter-pipeline**
2. Click **Run pipeline**
3. Fill in all required parameters
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output
6. Re-run with `deploymentStage: Deploy` to deploy

### Outputs

Note these values from the deployment outputs (needed for Stage 4):
- `devCenterResourceId`: The DevCenter resource ID
- `networkConnectionResourceId`: The Network Connection resource ID

## Stage 4: Deploy CloudOps Workload (Managed DevOps Pool)

Use the CloudOps pipeline to deploy the Managed DevOps Pool.

### Pipeline Parameters

#### Core Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionId` | CloudOps subscription ID (from Stage 1) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `workloadAlias` | Workload alias for naming | `cloudops` |
| `environment` | Environment type | `live` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `location` | Azure region | `canadacentral` |

#### DevCenter References (from Stage 3)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `devCenterResourceId` | DevCenter resource ID | `/subscriptions/.../devcenters/...` |

#### Spoke Networking References (from Stage 2)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `poolSubnetResourceId` | Pool subnet resource ID | `/subscriptions/.../subnets/agents` |

#### Managed DevOps Pool Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `poolMaximumConcurrency` | Maximum concurrent agents | `4` |
| `poolAgentSkuName` | VM SKU size | `Standard_D4s_v5` |
| `poolImageName` | Agent image | `ubuntu-22.04/latest` |
| `enableScaleToZero` | Enable scale-to-zero | `true` |

#### Azure DevOps Configuration

| Parameter | Description | Example |
|-----------|-------------|---------|
| `azureDevOpsOrganizationUrl` | Azure DevOps org URL | `https://dev.azure.com/myorg` |
| `azureDevOpsProjectNames` | Project scope (comma-separated, optional) | `Project1,Project2` |

#### Deployment Stack Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `denySettingsMode` | Protection level | `denyWriteAndDelete` |
| `actionOnUnmanage` | Cleanup behavior | `detachAll` |

### Running the Pipeline

1. Navigate to **Pipelines** > **cloudops-pipeline**
2. Click **Run pipeline**
3. Fill in all required parameters:
   - Enter the subscription ID from Stage 1
   - Enter DevCenter resource ID from Stage 3
   - Enter subnet resource ID from Stage 2
   - Configure pool settings
   - Enter Azure DevOps organization URL
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output carefully:
   - Verify pool configuration
   - Check subnet configuration
   - Confirm Azure DevOps organization
6. Re-run with `deploymentStage: Deploy` to deploy

### Verification

After deployment, verify:

1. **Resource Group Created**
   ```bash
   az group show --name rg-cloudops-live-cac-001 --subscription <cloudops-subscription-id>
   ```

2. **DevCenter Project Created**
   ```bash
   az devcenter admin project show \
     --name dcp-cloudops-live-cac-001 \
     --resource-group rg-cloudops-live-cac-001 \
     --subscription <cloudops-subscription-id>
   ```

3. **Managed DevOps Pool Created**
   ```bash
   az resource show \
     --resource-type "Microsoft.DevOpsInfrastructure/pools" \
     --name mdp-cloudops-live-cac-001 \
     --resource-group rg-cloudops-live-cac-001 \
     --subscription <cloudops-subscription-id>
   ```

4. **Agent Pool in Azure DevOps**
   - Go to Azure DevOps > Organization Settings > Agent Pools
   - Look for the pool named `mdp-cloudops-live-cac-001`
   - Verify agents are online (may take 5-10 minutes initially)

## Post-Deployment Configuration

### 1. Verify Azure DevOps Agent Pool

1. Go to **Organization Settings** > **Agent Pools** in Azure DevOps
2. Find the pool created by Managed DevOps Pools
3. Verify the pool shows as online
4. Note: Agents are provisioned on-demand when jobs are queued

### 2. Test Pool Functionality

Create a test pipeline to verify agents work:

```yaml
trigger: none

pool: mdp-cloudops-live-cac-001

steps:
  - script: |
      echo "Hello from Managed DevOps Pool!"
      uname -a
      cat /etc/os-release
    displayName: 'Test Agent'
```

### 3. Grant RBAC Permissions (If Needed)

If pool agents need access to other Azure resources, grant permissions:

```bash
# Get the pool's managed identity principal ID (from Azure Portal or CLI)
# Navigate to the pool resource and check Identity blade

# Grant Contributor at management group level
az role assignment create \
  --role "Contributor" \
  --assignee-object-id <pool-identity-principal-id> \
  --assignee-principal-type ServicePrincipal \
  --scope "/providers/Microsoft.Management/managementGroups/mg-corp"
```

## Troubleshooting

### Pool Deployment Failed

**Symptom**: Deployment fails at Managed DevOps Pool creation

**Possible Causes**:
1. DevCenter not found or invalid resource ID
2. Subnet not found or invalid resource ID
3. Azure DevOps organization URL invalid
4. Missing Azure DevOps permissions

**Resolution**:
1. Verify DevCenter resource ID from Stage 3 outputs
2. Verify subnet resource ID from Stage 2 outputs
3. Ensure Azure DevOps organization URL is correct format
4. Verify Administrator permissions in Azure DevOps

### No Agents in Azure DevOps

**Symptom**: Pool created but no agents visible in Azure DevOps

**Possible Causes**:
1. Pool not linked to Azure DevOps organization
2. Permission issues
3. Scale-to-zero active (normal behavior)

**Resolution**:
1. Check Azure DevOps organization URL in pool configuration
2. Verify Azure DevOps Administrator permissions
3. Queue a job to trigger agent provisioning (normal with scale-to-zero)

### Agents Cannot Reach Spoke VNets

**Symptom**: Pool agents cannot communicate with spoke resources

**Possible Causes**:
1. AVNM connectivity not configured
2. Network Connection not attached
3. NSG blocking traffic

**Resolution**:
1. Verify CloudOps subscription is in AVNM scope
2. Check Network Connection in DevCenter
3. Review NSG rules on pool subnet

### Resource Provider Not Registered

**Symptom**: Deployment fails with provider registration error

**Resolution**:
```bash
az provider register --namespace Microsoft.DevOpsInfrastructure
az provider register --namespace Microsoft.DevCenter

# Wait for registration to complete
az provider show --namespace Microsoft.DevOpsInfrastructure --query "registrationState"
```

## Manual Deployment

For local testing or manual deployment using Deployment Stacks.

### Stage 3: DevCenter

```bash
az stack sub create \
  --name "stack-devcenter-live-cac-001" \
  --subscription "<cloudops-subscription-id>" \
  --location "canadacentral" \
  --template-file code/bicep/cloudops/devcenter.bicep \
  --parameters code/bicep/cloudops/devcenter.bicepparam \
  --parameters subnetResourceId="<subnet-resource-id>" \
  --parameters logAnalyticsWorkspaceResourceId="<law-resource-id>" \
  --parameters owner="platform-team@organization.com" \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll \
  --yes
```

### Stage 4: CloudOps Pool

```bash
az stack sub create \
  --name "stack-cloudops-live-cac-001" \
  --subscription "<cloudops-subscription-id>" \
  --location "canadacentral" \
  --template-file code/bicep/cloudops/cloudops.bicep \
  --parameters code/bicep/cloudops/cloudops.bicepparam \
  --parameters devCenterResourceId="<devcenter-resource-id>" \
  --parameters poolSubnetResourceId="<subnet-resource-id>" \
  --parameters azureDevOpsOrganizationUrl="https://dev.azure.com/myorg" \
  --parameters owner="platform-team@organization.com" \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll \
  --yes
```

## Next Steps

- Review [CloudOps Overview](CloudOps-Overview.md) for architecture details
- Configure [Managing CloudOps](Managing-CloudOps.md) for ongoing operations
- Set up monitoring alerts for pool health
- Test agent connectivity to spoke VNets
