# Deploying Management Group Diagnostic Settings

## Prerequisites

1.  **Log Analytics Workspace**: Must be deployed (via Logging Infrastructure).
2.  **Service Principal**: Requires `Contributor` or `Monitoring Contributor` permissions on the target Management Group.

## Deployment Steps

### 1. Configure Variable Group

Ensure `common-variables` contains:
-   `logAnalyticsWorkspaceResourceId`: The full extraction from the Logging deployment output.

### 2. Run the Pipeline

Trigger the pipeline `code/pipelines/mg-diag-settings/mg-diag-settings-pipeline.yaml`.

**Parameters:**
-   **Top Level Management Group ID**: The root group ID (e.g., `mg-contoso`) to apply settings to.
-   **Log Analytics Workspace Resource ID**: Passed via variable group or runtime parameter.
-   **Location**: `canadacentral` (for deployment metadata).

### 3. Verification

1.  Go to the **Azure Portal** -> **Monitor** -> **Activity Log**.
2.  Check **Diagnostic Settings**.
3.  Verify the setting exists pointing to your central workspace.
