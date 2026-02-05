# Deploying Monitoring Infrastructure

## Prerequisites

1.  **Log Analytics Workspace**: Must be deployed (via Logging Infrastructure).
2.  **Service Principal**: Requires `Contributor` or `Monitoring Contributor` permissions.

## Deployment Steps

### 1. Configure Variable Group

Ensure `common-variables` contains:
-   `logAnalyticsWorkspaceResourceId`: The full ID of the central workspace.
-   `platformAlertEmail`: The email address to receive notifications.

### 2. Run the Pipeline

Trigger the pipeline `code/pipelines/monitoring/monitoring-pipeline.yaml`.

**Parameters:**
-   **Environment**: `live`
-   **Location**: `canadacentral`
-   **Instance**: `001`
-   **Log Analytics Workspace Resource ID**: Passed from variables.

### 3. Verification

1.  Go to **Azure Monitor** -> **Alerts** -> **Action Groups**.
2.  Verify the `ag-platform-team` (or similar) exists.
3.  Click **Test Action Group** to send a sample email.
