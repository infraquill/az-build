# Deploying Hub Infrastructure

This guide walks you through deploying the hub networking infrastructure.

## Prerequisites

Before deploying the hub infrastructure, ensure you have:

1. **Azure Subscription**: A dedicated hub/connectivity subscription (recommended)
2. **Required Permissions**: 
   - Owner or Contributor role on the target subscription
   - Or a custom role with resource group, network, and Key Vault permissions
3. **Management Group**: The target management group for AVNM scope must exist
4. **Log Analytics Workspace**: The monitoring infrastructure must be deployed first
5. **Azure CLI**: Installed and configured (for local deployment)
6. **Azure DevOps**: Access to the pipeline (for automated deployment)
7. **Service Connection**: Configured in Azure DevOps with appropriate permissions

## Configuration

### Step 1: Review Parameters File

The `hub.bicepparam` file contains the deployment configuration:

```bicep
using 'hub.bicep'

param workloadAlias = 'hub'
param environment = 'live'
param locationCode = 'cac'
param instanceNumber = '001'
param location = 'canadacentral'
param privateDnsZoneName = 'internal.organization.com'
param hubVnetAddressSpace = '10.0.0.0/16'
param logAnalyticsWorkspaceResourceId = ''
param owner = 'platform-team@organization.com'
param managedBy = 'Bicep'
param avnmManagementGroupId = 'mg-connectivity'
```

### Step 2: Customize Parameters

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|--------------|
| `workloadAlias` | Workload alias for naming | `hub` | Any alphanumeric string |
| `environment` | Environment name | `live` | `nonprod`, `dev`, `test`, `uat`, `staging`, `prod`, `live` |
| `locationCode` | Short location code | `cac` | `cac`, `cae`, `eus`, etc. |
| `instanceNumber` | Instance identifier | `001` | Three-digit string |
| `location` | Azure region | `canadacentral` | Any valid Azure region |
| `privateDnsZoneName` | Private DNS zone name | `internal.organization.com` | Valid DNS zone name |
| `hubVnetAddressSpace` | Hub VNet address space | `10.0.0.0/16` | Valid CIDR notation |
| `logAnalyticsWorkspaceResourceId` | Log Analytics workspace resource ID | - | Full resource ID |
| `owner` | Owner tag value | - | Email or team name |
| `managedBy` | Management tool tag | `Bicep` | Any string |
| `avnmManagementGroupId` | AVNM management group scope | `mg-connectivity` | Existing management group ID |

### Step 3: Configure Optional Components

Enable optional components by setting flags in the parameters file or pipeline:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enableAppGatewayWAF` | Enable Application Gateway with WAF | `false` |
| `enableFrontDoor` | Enable Azure Front Door (Standard) | `false` |
| `enableVpnGateway` | Enable VPN Gateway with P2S | `false` |
| `enableAzureFirewall` | Enable Azure Firewall | `false` |
| `enableDDoSProtection` | Enable DDoS Protection | `false` |
| `enableDnsResolver` | Enable Private DNS Resolver | `false` |
| `enableIpamPool` | Enable IPAM Pool | `false` |

**Optional Component Configuration:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vpnClientAddressPoolPrefix` | VPN client address pool | `172.16.0.0/24` |
| `azureFirewallTier` | Azure Firewall SKU | `Standard` |
| `ipamPoolAddressSpace` | IPAM pool address space | `10.0.0.0/8` |
| `ipamPoolDescription` | IPAM pool description | `Centralized IPAM pool for hub and spoke networks` |

## Deployment Methods

### Method 1: Azure DevOps Pipeline (Recommended)

The pipeline provides automated validation, what-if analysis, and deployment using Deployment Stacks.

#### Pipeline Stages

1. **Validate**: Validates the Bicep template and parameters
2. **What-If**: Shows what changes will be made before deployment
3. **Deploy**: Creates the hub infrastructure as a Deployment Stack

#### Running the Pipeline

1. Navigate to Azure DevOps Pipelines
2. Select `hub-pipeline`
3. Click "Run pipeline"
4. Configure the pipeline parameters:

| Parameter | Description |
|-----------|-------------|
| Hub Subscription ID | Target subscription for deployment |
| Workload Alias | Workload alias for naming (default: `hub`) |
| Environment | Target environment |
| Location Code | Short location code |
| Instance Number | Instance identifier |
| Location | Azure region |
| Private DNS Zone Name | Private DNS zone name |
| Hub VNet Address Space | Hub VNet address space (CIDR) |
| Log Analytics Workspace Resource ID | Resource ID from monitoring infrastructure |
| Owner | Resource owner |
| Managed By | Management tool |
| AVNM Management Group ID | Management group for AVNM scope |
| Enable Application Gateway WAF | Enable Application Gateway |
| Enable Front Door | Enable Azure Front Door |
| Enable VPN Gateway | Enable VPN Gateway |
| Enable Azure Firewall | Enable Azure Firewall |
| Enable DDoS Protection | Enable DDoS Protection |
| Enable DNS Resolver | Enable Private DNS Resolver |
| Enable IPAM Pool | Enable IPAM Pool |
| Deny Settings Mode | Protection level (`none`, `denyDelete`, `denyWriteAndDelete`) |
| Action on Unmanage | What happens to unmanaged resources |
| Deployment Stage | Which stage to run (`Validation`, `WhatIf`, `Deploy`) |

5. Review the validation and what-if results
6. Approve the deployment in the `hub` environment

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
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/hub/hub.bicep \
  --parameters code/bicep/hub/hub.bicepparam \
  --parameters logAnalyticsWorkspaceResourceId="/subscriptions/<sub-id>/resourceGroups/rg-monitoring-live-cac-001/providers/Microsoft.OperationalInsights/workspaces/law-monitoring-live-cac-001" \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll
```

#### What-If Analysis

```bash
az stack sub create \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/hub/hub.bicep \
  --parameters code/bicep/hub/hub.bicepparam \
  --parameters logAnalyticsWorkspaceResourceId="/subscriptions/<sub-id>/resourceGroups/rg-monitoring-live-cac-001/providers/Microsoft.OperationalInsights/workspaces/law-monitoring-live-cac-001" \
  --deny-settings-mode denyWriteAndDelete \
  --action-on-unmanage detachAll \
  --what-if
```

#### Deploy

```bash
az stack sub create \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/hub/hub.bicep \
  --parameters code/bicep/hub/hub.bicepparam \
  --parameters logAnalyticsWorkspaceResourceId="/subscriptions/<sub-id>/resourceGroups/rg-monitoring-live-cac-001/providers/Microsoft.OperationalInsights/workspaces/law-monitoring-live-cac-001" \
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
2. Verify the resource group exists: `rg-hub-<env>-<loc>-<instance>`
3. Open the resource group and verify all resources:
   - Network Watcher
   - Private DNS Zone
   - Azure Virtual Network Manager
   - Hub Virtual Network
   - Key Vault
   - Optional components (if enabled)
4. Check the virtual network subnets and address spaces
5. Verify diagnostic settings are configured for all resources

### Azure CLI

```bash
# Check the deployment stack
az stack sub show \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>"

# List resources in the resource group
az resource list \
  --resource-group "rg-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --output table

# Get virtual network details
az network vnet show \
  --name "vnet-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --subscription "<subscription-id>"

# List subnets
az network vnet subnet list \
  --vnet-name "vnet-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --output table

# Check AVNM
az network manager show \
  --name "avnm-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --subscription "<subscription-id>"

# Check IPAM Pool (if enabled)
az network manager ipam-pool show \
  --network-manager-name "avnm-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --name "ipam-hub-live-cac-001" \
  --subscription "<subscription-id>"
```

### Deployment Outputs

The deployment provides these outputs:

| Output | Description |
|--------|-------------|
| `resourceGroupName` | Name of the resource group |
| `networkWatcherResourceId` | Resource ID of Network Watcher |
| `privateDnsZoneName` | Name of the Private DNS Zone |
| `privateDnsZoneResourceId` | Resource ID of the Private DNS Zone |
| `avnmResourceId` | Resource ID of Azure Virtual Network Manager |
| `hubVnetName` | Name of the Hub Virtual Network |
| `hubVnetResourceId` | Resource ID of the Hub Virtual Network |
| `hubVnetSubnetResourceIds` | Array of subnet resource IDs |
| `appGatewayResourceId` | Resource ID of Application Gateway (if enabled) |
| `frontDoorResourceId` | Resource ID of Azure Front Door (if enabled) |
| `frontDoorName` | Name of Azure Front Door (if enabled) |
| `vpnGatewayResourceId` | Resource ID of VPN Gateway (if enabled) |
| `vpnGatewayName` | Name of VPN Gateway (if enabled) |
| `azureFirewallResourceId` | Resource ID of Azure Firewall (if enabled) |
| `azureFirewallName` | Name of Azure Firewall (if enabled) |
| `azureFirewallPrivateIp` | Private IP address of Azure Firewall (if enabled) |
| `ddosProtectionPlanResourceId` | Resource ID of DDoS Protection Plan (if enabled) |
| `ddosProtectionPlanName` | Name of DDoS Protection Plan (if enabled) |
| `keyVaultName` | Name of the Key Vault |
| `keyVaultResourceId` | Resource ID of the Key Vault |
| `keyVaultUri` | URI of the Key Vault |
| `dnsResolverResourceId` | Resource ID of Private DNS Resolver (if enabled) |
| `dnsResolverName` | Name of Private DNS Resolver (if enabled) |
| `ipamPoolResourceId` | Resource ID of IPAM Pool (if enabled) |
| `ipamPoolName` | Name of the IPAM Pool (if enabled) |
| `networkWatcherName` | Name of the Network Watcher |
| `avnmName` | Name of the Azure Virtual Network Manager |
| `appGatewayName` | Name of the Application Gateway (if enabled) |

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you have Owner or Contributor role on the subscription
   - Check the service connection has appropriate permissions
   - Verify management group permissions for AVNM scope

2. **Invalid Subscription**
   - Verify the subscription ID is correct
   - Ensure the subscription is active and accessible

3. **Name Already Exists**
   - Resource group or resource name may already exist
   - Change the instance number or use a different workloadAlias

4. **Deployment Stack Conflict**
   - A stack with the same name may already exist
   - Delete the existing stack or use a different name

5. **Log Analytics Workspace Not Found**
   - Verify the workspace resource ID is correct
   - Ensure the monitoring infrastructure is deployed first
   - Check the workspace exists in the same tenant

6. **Management Group Not Found**
   - Verify the AVNM management group ID exists
   - Ensure you have permissions to the management group
   - Check the management group hierarchy is deployed

7. **Subnet Address Space Conflicts**
   - Verify the hub VNet address space doesn't conflict with existing networks
   - Check subnet calculations don't overlap
   - Ensure sufficient address space for all subnets

8. **DDoS Protection Plan Creation**
   - DDoS Protection Plan must be created before the virtual network
   - If enabling DDoS Protection, ensure it's created first

9. **Deny Settings Blocking Changes**
   - If updating, the deny settings may block modifications
   - Temporarily change deny settings mode to `none` if needed

10. **IPAM Pool Configuration**
    - IPAM Pool requires AVNM with IPAM access enabled
    - Ensure the management group scope is correct
    - Verify address space doesn't conflict with existing allocations

## Next Steps

After deploying the hub infrastructure:

1. [Managing Hub Infrastructure](Managing-Hub-Infrastructure.md) - Learn about ongoing management
2. Configure virtual network peering with spoke networks
3. Set up routing tables and user-defined routes (if needed)
4. Configure Azure Firewall rules (if enabled)
5. Set up VPN Gateway connections (if enabled)
6. Configure Application Gateway backend pools and listeners (if enabled)
7. Link additional virtual networks to the Private DNS Zone
8. Configure IPAM Pool allocations for spoke networks
