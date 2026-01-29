# Managing Subscription Vending

This guide covers best practices and procedures for managing subscriptions created through the subscription vending process.

## Ongoing Management Tasks

### Viewing Subscription Details

Check subscription information:

```bash
# Get subscription details
az account show \
  --subscription <subscription-id> \
  --output json

# List all subscriptions
az account list \
  --output table

# Get subscription by alias
az account alias show \
  --name subcr-hub-live-cac-001

# List subscriptions in a management group
az account management-group subscription list \
  --name <management-group-id> \
  --output table
```

### Viewing Deployment History

Check the deployment that created the subscription:

```bash
# List tenant-level deployments
az deployment tenant list \
  --output table

# Get specific deployment details
az deployment tenant show \
  --name 'sub-vending-<build-number>' \
  --output json
```

### Updating Subscription Tags

Update tags on existing subscriptions:

```bash
# Update subscription tags
az account update \
  --subscription <subscription-id> \
  --set tags.Project=hub tags.Environment=prod tags.Owner='new-owner@organization.com'

# Add a new tag
az account update \
  --subscription <subscription-id> \
  --set tags.NewTag='value'

# Remove a tag
az account update \
  --subscription <subscription-id> \
  --remove tags.OldTag
```

### Moving Subscriptions Between Management Groups

Move a subscription to a different management group:

```bash
# Move subscription to a new management group
az account management-group subscription add \
  --name <target-management-group-id> \
  --subscription <subscription-id>

# Remove subscription from current management group (if needed)
az account management-group subscription remove \
  --name <source-management-group-id> \
  --subscription <subscription-id>
```

**Note**: Subscriptions can only be in one management group at a time. Moving a subscription will change policy inheritance and governance.

## Best Practices

### 1. Naming Convention

- **Consistency**: Always follow the `subcr-<workloadAlias>-<env>-<loc>-<instance>` pattern
- **Documentation**: Document the intent of each subscription
- **Avoid Conflicts**: Use unique instance numbers for each workloadAlias/environment combination
- **Review Regularly**: Periodically review subscription names for consistency

### 2. Management Group Placement

- **Organizational Alignment**: Place subscriptions in management groups that reflect organizational structure
- **Policy Inheritance**: Understand how policies from the management group affect the subscription
- **Governance**: Ensure management group placement aligns with governance requirements
- **Documentation**: Document why each subscription is in its management group

### 3. Tagging

- **Complete Information**: Ensure all required tags are present and accurate
- **Consistency**: Use consistent tag values across all subscriptions
- **Owner Updates**: Update owner tags when ownership changes
- **Regular Audits**: Periodically audit tags for accuracy and completeness

### 4. Billing and Cost Management

- **Billing Scope**: Verify billing scope is correctly configured for EA/MCA scenarios
- **Cost Allocation**: Use tags for cost allocation and chargeback
- **Budgets**: Set up budgets and alerts for subscriptions
- **Regular Reviews**: Review costs regularly and optimize spending

### 5. Access Control

- **RBAC**: Configure role-based access control appropriately
- **Least Privilege**: Grant minimum required permissions
- **Regular Reviews**: Periodically review access assignments
- **Documentation**: Document who has access and why

### 6. Subscription Lifecycle

- **Documentation**: Maintain documentation for each subscription
- **Workload Tracking**: Track the workload alias and owner of each subscription
- **Decommissioning**: Have a process for decommissioning unused subscriptions
- **Renaming**: Avoid renaming subscriptions after creation (use tags for additional context)

## Common Management Scenarios

### Scenario 1: Updating Subscription Owner

**Requirement**: Change the owner tag when ownership changes

**Solution**:
```bash
az account update \
  --subscription <subscription-id> \
  --set tags.Owner='new-owner@organization.com'
```

### Scenario 2: Moving Subscription to Different Management Group

**Requirement**: Move a subscription to a different management group for organizational changes

**Solution**:
```bash
# Move to new management group
az account management-group subscription add \
  --name <new-management-group-id> \
  --subscription <subscription-id>
```

**Considerations**:
- Policies from the new management group will apply
- Policies from the old management group will no longer apply
- Verify policy impact before moving

### Scenario 3: Adding Additional Tags

**Requirement**: Add custom tags for additional categorization

**Solution**:
```bash
az account update \
  --subscription <subscription-id> \
  --set tags.CostCenter='IT-001' tags.BusinessUnit='Engineering'
```

### Scenario 4: Updating Billing Scope

**Requirement**: Change billing scope for EA/MCA scenarios

**Note**: Billing scope cannot be changed after subscription creation through the vending process. This requires:
- Canceling and recreating the subscription (not recommended)
- Using Azure billing APIs (requires appropriate permissions)
- Contacting Azure support

### Scenario 5: Renaming Subscription Display Name

**Requirement**: Update the human-readable display name

**Solution**:
```bash
az account update \
  --subscription <subscription-id> \
  --name 'New Display Name'
```

**Note**: The subscription alias cannot be changed after creation.

### Scenario 6: Canceling a Subscription

**Requirement**: Cancel an unused subscription

**Solution**:
```bash
# Cancel subscription (requires subscription-level permissions)
az account cancel \
  --subscription <subscription-id>
```

**Considerations**:
- Ensure all resources are deleted or migrated
- Verify no critical workloads depend on the subscription
- Update documentation
- Consider moving to a decommissioned management group first

## Monitoring and Maintenance

### Regular Reviews

| Frequency | Task |
|-----------|------|
| Weekly | Review new subscriptions created |
| Monthly | Audit subscription tags and ownership |
| Quarterly | Review subscription placement in management groups |
| Annually | Review subscription lifecycle and decommission unused subscriptions |

### Health Checks

```bash
# Verify subscription is active
az account show \
  --subscription <subscription-id> \
  --query "{Name:name, State:state, TenantId:tenantId}"

# Check subscription tags
az account show \
  --subscription <subscription-id> \
  --query tags \
  --output json

# Verify management group assignment
az account management-group subscription show \
  --name <management-group-id> \
  --subscription <subscription-id>

# Check subscription alias
az account alias show \
  --name subcr-hub-live-cac-001
```

### Cost Monitoring Queries

Use Azure Cost Management for subscription cost analysis:

```bash
# Get subscription costs
az consumption usage list \
  --subscription <subscription-id> \
  --start-date <start-date> \
  --end-date <end-date>

# List cost by tag
az consumption usage list \
  --subscription <subscription-id> \
  --query "[?tags.Project=='hub']"
```

## Implementation Notes

This implementation uses direct Bicep resource definitions rather than the Azure Verified Module (AVM) sub-vending pattern. The AVM module was abandoned due to a critical bug where it referenced an invalid API version (`2025-04-01`) for `Microsoft.Management/managementGroups`.

### API Versions Used

| Resource Type | API Version | Purpose |
|---------------|-------------|---------|
| `Microsoft.Subscription/aliases` | `2024-08-01-preview` | Subscription creation |
| `Microsoft.Management/managementGroups/subscriptions` | `2024-02-01-preview` | Management group association |
| `Microsoft.Management/managementGroups` | `2023-04-01` | Management group reference |

### Updating API Versions

When updating API versions in the Bicep template:

1. **Check Azure Documentation**: Verify the new API version is available and stable
2. **Test**: Run the pipeline with `Validation` and `WhatIf` stages
3. **Deploy**: Run the pipeline with `Deploy` stage for new subscriptions

**Note**: API version updates only affect new deployments. Existing subscriptions are not modified.

## Troubleshooting

### Subscription Not Appearing in Management Group

1. **Check Deployment**: Verify the deployment completed successfully
2. **Verify Management Group**: Ensure the management group ID is correct
3. **Check Permissions**: Verify you have permissions to view the management group
4. **Wait for Propagation**: Management group assignments may take a few minutes

```bash
# Verify subscription is in management group
az account management-group subscription show \
  --name <management-group-id> \
  --subscription <subscription-id>
```

### Tags Not Applied

1. **Check Deployment Outputs**: Verify the deployment completed successfully
2. **Verify Tag Values**: Check tag values don't contain invalid characters
3. **Check Tag Limits**: Ensure you're not exceeding 50 tags per subscription
4. **Manual Application**: Apply tags manually if needed

```bash
# Check current tags
az account show \
  --subscription <subscription-id> \
  --query tags

# Apply tags manually
az account update \
  --subscription <subscription-id> \
  --set tags.Project=hub tags.Environment=prod
```

### Subscription Alias Issues

1. **Verify Alias**: Check the alias was created correctly
2. **Check Uniqueness**: Ensure the alias is unique
3. **List Aliases**: View all subscription aliases

```bash
# List all subscription aliases
az account alias list \
  --output table

# Show specific alias
az account alias show \
  --name subcr-hub-live-cac-001
```

### Billing Scope Issues

1. **Verify Format**: Check billing scope format is correct
2. **Check Permissions**: Ensure you have billing account permissions
3. **Verify Billing Account**: Confirm billing account and invoice section exist
4. **Contact Support**: Billing scope changes may require Azure support

### Access Issues

1. **Check RBAC**: Verify role assignments on the subscription
2. **Verify Management Group**: Check management group permissions
3. **Check Tenant**: Ensure you're in the correct tenant
4. **Review Permissions**: Verify you have appropriate permissions

```bash
# List role assignments on subscription
az role assignment list \
  --scope /subscriptions/<subscription-id> \
  --output table

# Check your access
az account show \
  --subscription <subscription-id>
```

## Related Documentation

- [Subscription Vending Overview](Subscription-Vending-Overview.md)
- [Deploying Subscription Vending](Deploying-Subscription-Vending.md)
- [Azure Subscription Documentation](https://docs.microsoft.com/azure/cost-management-billing/manage/)
- [Azure Management Groups](https://docs.microsoft.com/azure/governance/management-groups/)
