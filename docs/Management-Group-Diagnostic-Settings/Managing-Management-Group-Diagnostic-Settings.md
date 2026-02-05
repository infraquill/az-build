# Managing Management Group Diagnostic Settings

## Ongoing Management

### Updating Log Categories

To change which logs are collected:
1.  Open `code/bicep/mg-diag-settings/modules/diagnostic-setting.bicep`.
2.  Modify the `logs` array in the `diagnosticSettings` resource.
3.  Commit and redeploy.

### Changing Destination

If you need to send logs to a **Storage Account** or **Event Hub** (e.g., for SIEM integration):
1.  Update the Bicep module to accept `storageAccountId` or `eventHubAuthorizationRuleId`.
2.  Pass these parameters from the pipeline.

## Best Practices

-   **Log Everything**: At the Management Group level, volume is low but value is high. Keep all categories enabled.
-   **Centralize**: Always send to the central security workspace. Do not scatter Activity Logs across multiple workspaces unless required by specific compliance boundaries.
