# Managing Monitoring Infrastructure

## Ongoing Management

### Adding Usage Alerts

To add a new alert (e.g., for unexpected cost spikes or data ingestion volume):
1.  Open `code/bicep/monitoring/monitoring.bicep`.
2.  Add a new `Microsoft.Insights/scheduledQueryRules` resource.
3.  Reference the `logAnalyticsWorkspaceResourceId` parameter for the scope.

### Updating Notification Contacts

To change who receives alerts:
1.  Open `code/bicep/monitoring/monitoring.bicepparam` (or the pipeline variable).
2.  Update the email address parameter.
3.  **Note**: This updates the Action Group. Azure Service Health alerts pointing to this Group will automatically send to the new contact.

## Best Practices

-   **Action Group Reuse**: Create a few "Standard" Action Groups (e.g., "Platform Team", "Security Team") and reuse them across many Alert Rules. Do not create a 1:1 mapping of Alert-to-Group.
-   **Suppression**: Use Action Rules (Processing Rules) to suppress alerts during planned maintenance windows, rather than disabling the alert rules themselves.
