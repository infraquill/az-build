# Deploying Spoke Infrastructure

This guide covers the two-stage deployment process for provisioning spoke subscriptions with networking infrastructure.

## Prerequisites

Before deploying spoke infrastructure, ensure you have:

1. **Hub Infrastructure Deployed**
   - Hub VNet with AVNM configured
   - Private DNS Zone created
   - IPAM Pool (optional, if using centralized IP management)

2. **Monitoring Infrastructure Deployed**
   - Log Analytics Workspace available
   - Resource ID noted for diagnostic settings

3. **Required Information**
   - Hub subscription ID
   - Hub resource group name
   - Hub Private DNS Zone name and resource ID
   - Log Analytics Workspace resource ID
   - (Optional) Hub AVNM name and IPAM Pool name

4. **Azure DevOps Configuration**
   - Service connection with appropriate permissions
   - Variable group `common-variables` configured
   - Pipeline environments created

## Stage 1: Create Spoke Subscription

Use the subscription vending pipeline to create the spoke subscription.

### Pipeline Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionDisplayName` | Display name for the subscription | `WebApp Dev Subscription` |
| `workloadAlias` | Workload alias for naming | `webapp` |
| `environment` | Environment type | `dev` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `managementGroupId` | Target management group | `mg-corp-non-prod` |
| `workload` | Workload type | `Production` or `DevTest` |
| `owner` | Owner email/group | `webapp-team@organization.com` |

### Running the Pipeline

1. Navigate to **Pipelines** > **sub-vending-pipeline**
2. Click **Run pipeline**
3. Fill in the required parameters
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output
6. Re-run with `deploymentStage: Deploy` to create the subscription

### Outputs

After deployment, note the subscription ID from the pipeline output:
- `subscriptionId`: The new subscription's ID (needed for Stage 2)

## Stage 2: Deploy Spoke Networking

Use the spoke networking pipeline to deploy VNet and connect to hub.

### Pipeline Parameters

#### Core Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `subscriptionId` | Spoke subscription ID (from Stage 1) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `workloadAlias` | Workload alias for naming (match Stage 1) | `webapp` |
| `environment` | Environment type (match Stage 1) | `dev` |
| `locationCode` | Location code | `cac` |
| `instanceNumber` | Instance number | `001` |
| `location` | Azure region | `canadacentral` |

#### Network Configuration

| Parameter | Description | Example |
|-----------|-------------|---------|
| `spokeVnetAddressSpace` | VNet address space | `10.1.0.0/16` |

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
| `owner` | Owner email/group | `webapp-team@organization.com` |

#### IPAM Configuration (Optional)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `enableIpamAllocation` | Enable IPAM allocation | `true` or `false` |
| `hubAvnmName` | Hub AVNM name | `avnm-hub-live-cac-001` |
| `hubIpamPoolName` | Hub IPAM Pool name | `ipam-hub-live-cac-001` |

#### Deployment Stack Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `denySettingsMode` | Protection level | `denyWriteAndDelete` |
| `actionOnUnmanage` | Cleanup behavior | `detachAll` |

### Running the Pipeline

1. Navigate to **Pipelines** > **spoke-networking-pipeline**
2. Click **Run pipeline**
3. Fill in all required parameters:
   - Enter the subscription ID from Stage 1
   - Configure network settings
   - Enter hub infrastructure references
4. Select `deploymentStage: WhatIf` to preview changes
5. Review the what-if output carefully:
   - Verify VNet address space doesn't overlap
   - Check Private DNS Zone link configuration
   - Confirm IPAM allocation (if enabled)
6. Re-run with `deploymentStage: Deploy` to deploy

### Verification

After deployment, verify:

1. **Resource Group Created**
   ```
   az group show --name rg-webapp-dev-cac-001 --subscription <spoke-subscription-id>
   ```

2. **VNet Created**
   ```
   az network vnet show --name vnet-webapp-dev-cac-001 --resource-group rg-webapp-dev-cac-001 --subscription <spoke-subscription-id>
   ```

3. **Private DNS Zone Link**
   ```
   az network private-dns link vnet show --name vnet-webapp-dev-cac-001-link --zone-name internal.organization.com --resource-group rg-hub-live-cac-001 --subscription <hub-subscription-id>
   ```

4. **AVNM Connectivity** (check in Azure Portal)
   - Navigate to Hub subscription > AVNM > Connectivity configurations
   - Verify spoke VNet is included

## Custom Subnet Configuration

By default, a single `workload` subnet is created. For custom subnets, modify the `spoke-networking.bicepparam` file:

```bicep
param customSubnets = [
  {
    name: 'web'
    addressPrefix: '10.1.0.0/24'
  }
  {
    name: 'app'
    addressPrefix: '10.1.1.0/24'
  }
  {
    name: 'data'
    addressPrefix: '10.1.2.0/24'
  }
]
```

Then commit the changes and re-run the pipeline.

## Dev Team Handoff

After spoke deployment, hand over to the development team:

### 1. Grant Access

Assign the dev team appropriate RBAC roles:

```bash
# Contributor on the subscription
az role assignment create \
  --role "Contributor" \
  --assignee "<team-group-id>" \
  --scope "/subscriptions/<spoke-subscription-id>"

# Or scoped to resource group
az role assignment create \
  --role "Contributor" \
  --assignee "<team-group-id>" \
  --scope "/subscriptions/<spoke-subscription-id>/resourceGroups/rg-webapp-dev-cac-001"
```

### 2. Provide Documentation

Share the following with the dev team:

| Information | Value |
|-------------|-------|
| Subscription ID | `<spoke-subscription-id>` |
| Resource Group | `rg-webapp-dev-cac-001` |
| VNet Name | `vnet-webapp-dev-cac-001` |
| VNet Address Space | `10.1.0.0/16` |
| Available Subnets | `workload (10.1.0.0/24)` |
| Private DNS Zone | `internal.organization.com` |

### 3. Explain Constraints

Inform the dev team:

- **Cannot Modify**: VNet, subnets, Private DNS links (protected by Deployment Stack)
- **Can Create**: VMs, App Services, databases, storage accounts, etc.
- **DNS Resolution**: Automatic via `*.internal.organization.com`
- **Hub Connectivity**: Automatic via AVNM (no peering needed)

### 4. Support Contacts

Provide contacts for:
- Network changes (address space, new subnets)
- Connectivity issues
- DNS resolution problems

## Troubleshooting

### Private DNS Zone Link Failed

**Symptom**: Deployment fails at Private DNS Zone link step

**Possible Causes**:
1. Service principal lacks permissions on hub subscription
2. Private DNS Zone name mismatch
3. VNet link already exists with same name

**Resolution**:
1. Verify service principal has `Private DNS Zone Contributor` on hub resource group
2. Check `hubPrivateDnsZoneName` matches exactly
3. Delete existing link if duplicate

### IPAM Allocation Failed

**Symptom**: Deployment fails at IPAM allocation step

**Possible Causes**:
1. AVNM name or IPAM Pool name incorrect
2. Address space already allocated
3. Service principal lacks IPAM permissions

**Resolution**:
1. Verify `hubAvnmName` and `hubIpamPoolName` match hub outputs
2. Choose a different address space
3. Grant `Network Contributor` on hub resource group

### AVNM Connectivity Not Working

**Symptom**: Spoke cannot reach hub resources

**Possible Causes**:
1. Spoke subscription not in AVNM scope
2. AVNM connectivity configuration not committed
3. Network security rules blocking traffic

**Resolution**:
1. Verify subscription is under management group in AVNM scope
2. Check AVNM connectivity configuration in Azure Portal
3. Review NSG rules on both hub and spoke

### Deployment Stack Deny Error

**Symptom**: Cannot modify VNet resources

**This is Expected**: The Deployment Stack protects VNet configuration

**If Changes Needed**:
1. Update the Bicep template
2. Re-run the spoke networking pipeline
3. Changes will be applied through the stack

## Address Space Planning

### Recommended Approach

| Environment | Address Range | Example Spokes |
|-------------|---------------|----------------|
| Hub | `10.0.0.0/16` | Hub VNet |
| Dev | `10.1.0.0/16` - `10.9.0.0/16` | webapp-dev: `10.1.0.0/16` |
| Test | `10.10.0.0/16` - `10.19.0.0/16` | webapp-test: `10.10.0.0/16` |
| Prod | `10.20.0.0/16` - `10.99.0.0/16` | webapp-prod: `10.20.0.0/16` |

### Using IPAM

If IPAM is enabled:
1. Check available address space in IPAM Pool
2. Request allocation from platform team
3. Use allocated address in pipeline parameters

## Next Steps

- Review [Spoke Infrastructure Overview](Spoke-Infrastructure-Overview.md) for architecture details
- Configure additional spokes for other workloads
- Set up monitoring alerts for spoke resources
