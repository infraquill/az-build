# Deploying Logging Infrastructure

## Prerequisites

1.  **Management Subscription**: A subscription dedicated to management/platform resources must exist.
2.  **Service Principal**: Creating the pipeline connection requires an SPN with `Contributor` access to the Management Subscription.

## Deployment Steps

### 1. Configure Variable Group

Ensure the `common-variables` group contains:
-   `managementSubscriptionId`: ID of the Management Subscription.
-   `defaultOwner`: Email of the owner.
-   `managedBy`: Tool name (e.g., `Bicep`).

### 2. Run the Pipeline

Trigger the pipeline `code/pipelines/logging/logging-pipeline.yaml`.

**Parameters:**
-   **Environment**: `live`
-   **Location**: `canadacentral`
-   **Instance**: `01`
-   **Data Retention**: `60` (Default)

### 3. Validation

The pipeline performs:
1.  **Validate**: Checks the template syntax.
2.  **Preview**: Runs `what-if` analysis to show changes.
3.  **Deploy**: Creates resources using Deployment Stacks.

## Outputs

After deployment, note the **Resource ID** of the Log Analytics Workspace. You will need this for:
-   Deploying Diagnostic Settings.
-   Configuring Monitoring Alerts.
