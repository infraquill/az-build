# Managing Role Assignments

## Ongoing Management

### Adding a New Assignment

To grant access to a new team:

1.  **Update `role-assignments.bicepparam`**: Add a new object to the `roleAssignments` array.
    ```bicep
    {
      principalId: '<new-group-object-id>'
      roleDefinitionId: '<role-definition-id>'
      description: 'New Team Access'
      principalType: 'Group'
    }
    ```
2.  **Commit and Push**: Review the Pull Request.
3.  **Deploy**: Run the pipeline to apply the changes.

### Removing an Assignment

1.  **Remove from `role-assignments.bicepparam`**: Delete the object from the array.
2.  **Deploy**: The deployment stack is configured with `denySettingsMode` (usually `denyWriteAndDelete`). However, for the stack to remove the resource, the `actionOnUnmanage` setting controls behavior.
    -   If `actionOnUnmanage` is `detachAll`, the assignment remains but is no longer managed.
    -   If `actionOnUnmanage` is `deleteAll`, the assignment is removed from Azure.
    -   **Check your pipeline configuration** for the active `actionOnUnmanage` setting.

## Best Practices

-   **Use Groups, Not Users**: Always assign roles to Azure AD Groups. This decouples infrastructure changes from personnel changes.
-   **Least Privilege**: Assign the minimum required role (e.g., `Reader` instead of `Contributor` if write access isn't needed).
-   **Audit Assignments**: Regularly review the `role-assignments.bicepparam` file to ensure strictly necessary access is maintained.
