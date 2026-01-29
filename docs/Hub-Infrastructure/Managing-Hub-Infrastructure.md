# Managing Hub Infrastructure

This guide covers best practices and procedures for managing your hub infrastructure after deployment.

## Ongoing Management Tasks

### Updating Configuration

To update the hub infrastructure configuration:

1. **Modify Parameters**: Update values in the pipeline run or parameters file
2. **Run Pipeline**: Execute the pipeline with the `Deploy` stage
3. **Verify Changes**: Confirm updates in the Azure Portal

#### Example: Enabling Azure Firewall

1. Run the pipeline with `enableAzureFirewall=true`
2. The deployment stack will create the Azure Firewall and required resources
3. Verify the firewall is deployed and configured correctly

#### Example: Changing Hub VNet Address Space

**Warning**: Changing the address space after deployment requires careful planning:

1. Ensure no resources are using the current address space
2. Update all peering connections
3. Update routing tables
4. Run the pipeline with the new address space
5. Update all dependent configurations

### Viewing Deployment Stack

Check the current state of the deployment stack:

```bash
az stack sub show \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --output yaml
```

This shows:
- Managed resources
- Deny settings configuration
- Action on unmanage setting
- Last deployment timestamp

### Listing Managed Resources

View all resources managed by the stack:

```bash
az stack sub show \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --query "resources[].id" \
  --output table
```

## Best Practices

### 1. Network Design

- **Address Space Planning**: Plan address spaces carefully to avoid conflicts
- **Subnet Sizing**: Ensure subnets are appropriately sized for their purpose
- **Growth Planning**: Reserve address space for future expansion
- **Documentation**: Maintain network diagrams and address space documentation

### 2. Security

- **Azure Firewall Rules**: Regularly review and update firewall rules
- **Network Security Groups**: Apply NSGs at subnet level where appropriate
- **Private Endpoints**: Use private endpoints for Azure services
- **DDoS Protection**: Enable DDoS Protection for production environments
- **Key Vault Access**: Limit Key Vault access to authorized users and services

### 3. Monitoring

- **Diagnostic Settings**: Ensure all resources have diagnostic settings configured
- **Log Analytics**: Regularly review logs in the Log Analytics workspace
- **Network Watcher**: Use Network Watcher for troubleshooting connectivity issues
- **Alerts**: Configure alerts for critical network events

### 4. Cost Optimization

- **Right-Sizing**: Review resource SKUs and sizes regularly
- **Reserved Instances**: Consider reserved instances for VPN Gateway and Application Gateway
- **Traffic Analysis**: Monitor data transfer costs
- **Unused Resources**: Remove or disable unused optional components

### 5. IPAM Management

If IPAM Pool is enabled:

- **Centralized Management**: Use IPAM Pool for all network address allocations
- **Documentation**: Document all IPAM allocations
- **Conflict Prevention**: Check IPAM Pool before allocating new address spaces
- **Regular Audits**: Review IPAM allocations quarterly

### 6. Deployment Stack Management

- **Use Deny Settings**: Enable `denyWriteAndDelete` for production
- **Regular Reviews**: Periodically review stack configuration
- **Document Changes**: Track all modifications to the stack
- **Backup Plans**: Maintain backup of parameters and configurations

## Common Management Scenarios

### Scenario 1: Enabling Optional Components

**Requirement**: Enable Azure Firewall after initial deployment

**Solution**:
1. Run the pipeline with `enableAzureFirewall=true`
2. Configure firewall rules post-deployment
3. Update route tables to use Azure Firewall as next hop

### Scenario 2: Adding Spoke Network to IPAM Pool

**Requirement**: Allocate address space for a new spoke network

**Solution**:
1. Determine required address space size
2. Check IPAM Pool for available space
3. Create static CIDR allocation in IPAM Pool
4. Use allocated address space for spoke network

### Scenario 3: Updating Private DNS Zone

**Requirement**: Link additional virtual networks to Private DNS Zone

**Solution**:
1. Update the Bicep template to include additional VNet links
2. Run the pipeline to apply changes
3. Or manually create VNet links via Azure Portal or CLI

### Scenario 4: Scaling Application Gateway

**Requirement**: Increase Application Gateway capacity

**Solution**:
1. Update the `capacity` parameter in the Bicep template
2. Run the pipeline to apply changes
3. Monitor performance after scaling

### Scenario 5: Updating VPN Gateway Configuration

**Requirement**: Change VPN client address pool

**Solution**:
1. Update `vpnClientAddressPoolPrefix` parameter
2. Run the pipeline to apply changes
3. Update VPN client configurations

### Scenario 6: Recovering from Accidental Deletion

If deny settings are configured, resources cannot be deleted. If recovery is needed:

1. **Redeploy the Stack**: Run the pipeline with `Deploy` stage
2. **Check Stack Status**: Verify all resources are recreated
3. **Restore Configuration**: Re-apply any custom configurations

## Monitoring and Maintenance

### Regular Reviews

| Frequency | Task |
|-----------|------|
| Daily | Check resource health and availability |
| Weekly | Review network traffic and performance |
| Monthly | Analyze costs and optimize resources |
| Quarterly | Review security rules and access controls |
| Annually | Evaluate architecture and capacity planning |

### Health Checks

```bash
# Verify virtual network is operational
az network vnet show \
  --name "vnet-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --query "{Name:name, ProvisioningState:provisioningState, AddressSpace:addressSpace}"

# Check deployment stack status
az stack sub show \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --query "{Name:name, ProvisioningState:provisioningState}"

# Verify diagnostic settings
az monitor diagnostic-settings list \
  --resource "/subscriptions/<sub-id>/resourceGroups/rg-hub-live-cac-001/providers/Microsoft.Network/virtualNetworks/vnet-hub-live-cac-001" \
  --output table

# Check Azure Firewall status (if enabled)
az network firewall show \
  --name "afw-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --query "{Name:name, ProvisioningState:provisioningState, ThreatIntelMode:threatIntelMode}"

# Verify VPN Gateway status (if enabled)
az network vnet-gateway show \
  --name "vpngw-hub-live-cac-001" \
  --resource-group "rg-hub-live-cac-001" \
  --query "{Name:name, ProvisioningState:provisioningState, GatewayType:gatewayType}"
```

### Network Monitoring Queries

Use Log Analytics workspace for network monitoring:

#### Virtual Network Flow Logs

```kql
AzureDiagnostics
| where ResourceType == "VIRTUALNETWORKS"
| where Category == "FlowLog"
| summarize count() by bin(TimeGenerated, 1h)
| render timechart
```

#### Application Gateway Access Logs

```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"
| summarize count() by bin(TimeGenerated, 1h), ServerStatus
| render timechart
```

#### Azure Firewall Logs

```kql
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where Category == "AzureFirewallApplicationRule" or Category == "AzureFirewallNetworkRule"
| summarize count() by bin(TimeGenerated, 1h), Category
| render timechart
```

## Updating AVM Modules

When a new version of an Azure Verified Module is available:

1. **Check Current Version**: Review `hub.bicep` for the current module versions
2. **Find Latest Version**: Check the [Azure/bicep-registry-modules](https://github.com/Azure/bicep-registry-modules) repository
3. **Review Changes**: Check the module's `version.json` and changelog
4. **Update Reference**: Update the module version in the Bicep file
5. **Test**: Run the pipeline with `Validation` and `WhatIf` stages
6. **Deploy**: Run the pipeline with `Deploy` stage

Example update:
```bicep
// From:
module hubVnet 'br/public:avm/res/network/virtual-network:0.7.0' = {

// To:
module hubVnet 'br/public:avm/res/network/virtual-network:0.8.0' = {
```

## Troubleshooting

### Cannot Modify Resources

If deny settings are blocking legitimate changes:

1. **Update Stack**: Temporarily change deny settings mode to `none`
2. **Make Changes**: Apply necessary modifications
3. **Restore Settings**: Re-enable deny settings after changes

```bash
# Temporarily disable deny settings
az stack sub create \
  --name "stack-hub-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/hub/hub.bicep \
  --parameters code/bicep/hub/hub.bicepparam \
  --deny-settings-mode none \
  --action-on-unmanage detachAll \
  --yes
```

### Network Connectivity Issues

1. **Check Peering**: Verify virtual network peering is configured correctly
2. **Review Routes**: Check route tables and user-defined routes
3. **Firewall Rules**: Verify Azure Firewall rules allow required traffic
4. **NSG Rules**: Check Network Security Group rules
5. **DNS Resolution**: Verify Private DNS Zone configuration

### High Costs

1. **Identify Sources**: Use cost analysis to identify high-cost resources
2. **Right-Size Resources**: Review and adjust resource SKUs
3. **Optimize Traffic**: Reduce unnecessary data transfer
4. **Reserved Instances**: Consider reserved instances for predictable workloads

### IPAM Pool Issues

1. **Check Availability**: Verify sufficient address space in IPAM Pool
2. **Review Allocations**: Check for conflicting allocations
3. **Validate Scope**: Ensure management group scope is correct
4. **Check Permissions**: Verify AVNM permissions for IPAM

### VPN Gateway Connection Issues

1. **Check Gateway Status**: Verify VPN Gateway is operational
2. **Review Client Configuration**: Check VPN client settings
3. **Validate Certificates**: Ensure certificates are valid and not expired
4. **Check Routes**: Verify routes are configured correctly

## Related Documentation

- [Hub Infrastructure Overview](Hub-Infrastructure-Overview.md)
- [Deploying Hub Infrastructure](Deploying-Hub-Infrastructure.md)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [Azure Virtual Network Manager](https://docs.microsoft.com/azure/virtual-network-manager/)
- [Azure Deployment Stacks](https://docs.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
