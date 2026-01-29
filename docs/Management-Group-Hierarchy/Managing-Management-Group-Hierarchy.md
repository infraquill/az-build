# Managing Management Group Hierarchy

This guide covers best practices and procedures for managing your Azure Management Group hierarchy after initial creation.

## Ongoing Management Tasks

### Adding New Management Groups

To add new management groups to your hierarchy:

1. **Edit the Parameters File**:
   - Open `mg-hierarchy.bicepparam`
   - Add new management group definitions to the `managementGroups` array
   - Ensure parents are listed before children

2. **Example - Adding a New Management Group**:
   ```bicep
   param managementGroups = [
     // ... existing management groups ...
     {
       id: 'new-mg-id'
       displayName: 'New Management Group'
       parentId: 'parent-mg-id'  // Must be an existing management group ID
     }
   ]
   ```

3. **Deploy Changes**:
   - Run the pipeline or use Azure CLI
   - The deployment will create the new management group

### Modifying Existing Management Groups

To update properties of existing management groups:

1. **Update Display Name**:
   ```bicep
   {
     id: 'existing-mg-id'  // ID cannot change
     displayName: 'Updated Display Name'
     parentId: 'parent-mg-id'
   }
   ```

2. **Change Parent**:
   ```bicep
   {
     id: 'existing-mg-id'
     displayName: 'Display Name'
     parentId: 'new-parent-mg-id'  // Change parent
   }
   ```
   **Note**: Changing a management group's parent moves all child management groups and subscriptions with it.

### Removing Management Groups

**Important**: Management groups can only be deleted if they:
- Have no child management groups
- Have no subscriptions assigned
- Have no policies or role assignments

**Steps to Remove**:

1. **Move or Remove Children**:
   - Move all child management groups to a different parent
   - Move all subscriptions to a different management group

2. **Remove Policies and Assignments**:
   - Remove all policy assignments
   - Remove all role assignments

3. **Update Parameters File**:
   - Remove the management group from the `managementGroups` array

4. **Deploy**:
   - The management group will be removed from the template
   - However, you must manually delete it in Azure Portal or via CLI:
     ```bash
     az account management-group delete --name <mg-id>
     ```

## Best Practices

### 1. Naming Conventions

- **IDs**: Use lowercase, alphanumeric characters with hyphens
  - Good: `corp-prod`, `platform-mgmt`
  - Bad: `Corp Prod`, `platform_mgmt_01`

- **Display Names**: Use clear, descriptive names
  - Good: `Corporate Production`, `Platform Management`
  - Bad: `MG1`, `Prod`

### 2. Hierarchy Design

- **Keep it Simple**: Avoid deep nesting (more than 4-5 levels)
- **Logical Grouping**: Group by business function, environment, or team
- **Scalability**: Design for future growth

### 3. Subscription Management

- **Assign Subscriptions Early**: Move subscriptions to appropriate management groups after creation
- **Use Naming Conventions**: Align subscription names with management group structure
- **Document Assignments**: Maintain documentation of which subscriptions belong where

### 4. Policy Management

- **Apply at Appropriate Levels**: 
  - Organization-wide policies at Organization Root
  - Platform policies at Platform level
  - Workload-specific policies at Landing Zone level

- **Use Policy Sets**: Group related policies into initiatives
- **Test in Sandbox**: Test new policies in Sandbox before applying to production

### 5. Access Control

- **Principle of Least Privilege**: Grant minimum required permissions
- **Use Management Group Scope**: Apply RBAC at management group level for efficiency
- **Regular Audits**: Review access assignments regularly

## Common Management Scenarios

### Scenario 1: Adding a New Environment

**Requirement**: Add a "Development" environment under Landing Zone

**Solution**:
```bicep
{
  id: 'dev'
  displayName: 'Development'
  parentId: 'landing-zone'
}
```

### Scenario 2: Reorganizing Structure

**Requirement**: Move "Sandbox" under "Platform"

**Solution**:
```bicep
{
  id: 'sandbox'
  displayName: 'Sandbox'
  parentId: 'platform'  // Changed from 'org-name'
}
```

**Note**: This will move Sandbox and all its children under Platform.

### Scenario 3: Renaming Management Group

**Requirement**: Rename "Corp Production" to "Corporate Production"

**Solution**:
```bicep
{
  id: 'corp-prod'  // ID stays the same
  displayName: 'Corporate Production'  // Display name updated
  parentId: 'landing-zone'
}
```

## Monitoring and Maintenance

### Regular Reviews

- **Monthly**: Review management group structure for optimization opportunities
- **Quarterly**: Audit policy assignments and compliance
- **Annually**: Review overall hierarchy design and alignment with business needs

### Health Checks

1. **Verify Hierarchy Structure**:
   ```bash
   az account management-group show --name <mg-id> --expand
   ```

2. **Check Subscription Assignments**:
   ```bash
   az account management-group subscription show --name <mg-id>
   ```

3. **Review Policy Compliance**:
   - Use Azure Policy compliance dashboard
   - Review policy assignment results

### Documentation

- **Maintain Hierarchy Diagram**: Keep visual representation updated
- **Document Decisions**: Record why management groups were created or modified
- **Update Runbooks**: Keep operational procedures current

## Troubleshooting

### Management Group Not Appearing

- **Check Permissions**: Verify you have access to view the management group
- **Refresh Portal**: Management group changes may take a few minutes to appear
- **Verify Deployment**: Check deployment status and outputs

### Cannot Delete Management Group

- **Check Children**: Ensure no child management groups exist
- **Check Subscriptions**: Move all subscriptions to another management group
- **Check Policies**: Remove all policy assignments
- **Check RBAC**: Remove all role assignments

### Deployment Failures

- **Review Logs**: Check Azure deployment logs for specific errors
- **Validate Parameters**: Ensure all IDs are correct and parents exist
- **Check Permissions**: Verify service principal has required permissions

## Related Documentation

- [Management Group Hierarchy Overview](Management-Group-Hierarchy-Overview.md)
- [Creating Management Group Hierarchy](Creating-Management-Group-Hierarchy.md)
- [Azure Management Groups Documentation](https://docs.microsoft.com/azure/governance/management-groups/)
