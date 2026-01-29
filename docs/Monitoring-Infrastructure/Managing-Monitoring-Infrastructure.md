# Managing Monitoring Infrastructure

This guide covers best practices and procedures for managing your monitoring infrastructure after deployment.

## Ongoing Management Tasks

### Updating Configuration

To update the monitoring infrastructure configuration:

1. **Modify Parameters**: Update values in the pipeline run or parameters file
2. **Run Pipeline**: Execute the pipeline with the `Deploy` stage
3. **Verify Changes**: Confirm updates in the Azure Portal

#### Example: Increasing Data Retention

1. Run the pipeline with a new `dataRetention` value (e.g., `90` days)
2. The deployment stack will update the workspace configuration
3. Verify the new retention setting in the workspace properties

### Viewing Deployment Stack

Check the current state of the deployment stack:

```bash
az stack sub show \
  --name "stack-monitoring-live-cac-001" \
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
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --query "resources[].id" \
  --output table
```

## Best Practices

### 1. Workspace Management

- **Single Workspace per Environment**: Use one workspace per environment to simplify cost management
- **Appropriate Retention**: Balance cost with compliance requirements
- **Access Control**: Limit who can query and modify the workspace

### 2. Cost Optimization

Monitor and optimize costs:

- **Review Ingestion Volume**: Regularly check data ingestion rates
- **Optimize Retention**: Reduce retention for non-critical data
- **Use Commitment Tiers**: Consider commitment tiers for predictable costs
- **Archive Old Data**: Export old data to storage for long-term retention

```bash
# Check workspace usage
az monitor log-analytics workspace show \
  --workspace-name "law-monitoring-live-cac-001" \
  --resource-group "rg-monitoring-live-cac-001" \
  --query "{Name:name, RetentionDays:retentionInDays, Sku:sku.name}" \
  --output table
```

### 3. Security

- **Enable Azure RBAC**: Use Azure RBAC for workspace access
- **Limit Direct Access**: Use Azure Private Link for secure access
- **Monitor Access**: Enable auditing for workspace access
- **Secure Outputs**: Protect workspace keys and connection strings

### 4. Data Management

- **Organize with Tables**: Use custom tables for different data types
- **Data Collection Rules**: Configure DCRs for efficient data collection
- **Transformation**: Apply transformations to reduce data volume

### 5. Deployment Stack Management

- **Use Deny Settings**: Enable `denyWriteAndDelete` for production
- **Regular Reviews**: Periodically review stack configuration
- **Document Changes**: Track all modifications to the stack

## Common Management Scenarios

### Scenario 1: Updating Data Retention

**Requirement**: Increase retention from 60 to 90 days

**Solution**:
Run the pipeline with updated parameters:
```yaml
dataRetention: 90
```

### Scenario 2: Adding Tags

**Requirement**: Add a new tag to resources

**Solution**:
1. Update the Bicep template to include new tags
2. Run the pipeline to apply changes

### Scenario 3: Recovering from Accidental Deletion

If deny settings are configured, resources cannot be deleted. If recovery is needed:

1. **Redeploy the Stack**: Run the pipeline with `Deploy` stage
2. **Check Stack Status**: Verify all resources are recreated

### Scenario 4: Moving to a Different Subscription

**Steps**:
1. Create a new stack in the target subscription
2. Configure data export from old workspace to new
3. Update all diagnostic settings to point to new workspace
4. Decommission old workspace after migration

## Monitoring the Monitor

### Workspace Health

Monitor your Log Analytics workspace:

```kql
// Check ingestion rate
Usage
| where TimeGenerated > ago(1d)
| summarize DataGB = sum(Quantity) / 1000 by bin(TimeGenerated, 1h)
| render timechart
```

### Common KQL Queries

#### Data Volume by Solution

```kql
Usage
| where TimeGenerated > ago(7d)
| summarize TotalGB = sum(Quantity) / 1000 by Solution
| sort by TotalGB desc
```

#### Data Volume by Table

```kql
Usage
| where TimeGenerated > ago(7d)
| summarize TotalGB = sum(Quantity) / 1000 by DataType
| sort by TotalGB desc
| take 20
```

#### Heartbeat Status

```kql
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(5m)
```

## Maintenance Tasks

### Regular Reviews

| Frequency | Task |
|-----------|------|
| Daily | Check workspace availability and ingestion |
| Weekly | Review data volume trends |
| Monthly | Analyze cost and optimize retention |
| Quarterly | Review access controls and security |
| Annually | Evaluate architecture and capacity |

### Health Checks

```bash
# Verify workspace is operational
az monitor log-analytics workspace show \
  --workspace-name "law-monitoring-live-cac-001" \
  --resource-group "rg-monitoring-live-cac-001" \
  --query "{Name:name, ProvisioningState:provisioningState}"

# Check deployment stack status
az stack sub show \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --query "{Name:name, ProvisioningState:provisioningState}"
```

## Updating the AVM Module

When a new version of the Azure Verified Module is available:

1. **Check Current Version**: Review `monitoring.bicep` for the current module version
2. **Find Latest Version**: Check the [Azure/bicep-registry-modules](https://github.com/Azure/bicep-registry-modules) repository
3. **Update Reference**: Update the module version in the Bicep file
4. **Test**: Run the pipeline with `Validation` and `WhatIf` stages
5. **Deploy**: Run the pipeline with `Deploy` stage

Example update:
```bicep
// From:
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.0' = {

// To:
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
```

## Troubleshooting

### Workspace Not Receiving Data

1. **Check Diagnostic Settings**: Verify resources have diagnostic settings configured
2. **Verify Workspace ID**: Ensure the correct workspace is targeted
3. **Check Agent Health**: For VM-based collection, verify agent status
4. **Review Ingestion Delays**: Data may take a few minutes to appear

### Cannot Modify Resources

If deny settings are blocking legitimate changes:

1. **Update Stack**: Temporarily change deny settings mode to `none`
2. **Make Changes**: Apply necessary modifications
3. **Restore Settings**: Re-enable deny settings after changes

```bash
# Temporarily disable deny settings
az stack sub create \
  --name "stack-monitoring-live-cac-001" \
  --subscription "<subscription-id>" \
  --location canadacentral \
  --template-file code/bicep/monitoring/monitoring.bicep \
  --parameters code/bicep/monitoring/monitoring.bicepparam \
  --deny-settings-mode none \
  --action-on-unmanage detachAll \
  --yes
```

### High Ingestion Costs

1. **Identify Sources**: Use KQL to find high-volume data sources
2. **Optimize Collection**: Reduce verbosity or filter unnecessary data
3. **Consider Tiers**: Evaluate commitment tier pricing
4. **Archive Data**: Export older data to cheaper storage

## Related Documentation

- [Monitoring Infrastructure Overview](Monitoring-Infrastructure-Overview.md)
- [Deploying Monitoring Infrastructure](Deploying-Monitoring-Infrastructure.md)
- [Azure Log Analytics Documentation](https://docs.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)
- [Azure Deployment Stacks](https://docs.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
