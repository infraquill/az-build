# Deploying Role Assignments

## Prerequisites

Before deployment, ensure you have:

1.  **Management Group Permissions**: The Service Principal used by the pipeline must have `Owner` or `User Access Administrator` permissions on the target Management Group hierarchy.
2.  **Service Principal / Group IDs**: You must know the Object IDs of the principals you wish to assign.
3.  **Role Definition IDs**: You must know the IDs of the roles (e.g., `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` for Owner).

## Deployment Steps

The deployment is managed via the Azure DevOps pipeline: `code/pipelines/role-assignments/role-assignments-pipeline.yaml`.

### 1. Configure Variable Group

Ensure your variable group (e.g., `role-assignments-variables`) contains the necessary configuration or pass parameters at runtime.

### 2. Run the Pipeline

Trigger the pipeline with the following parameters:

-   **Top Level Management Group ID**: The root of where assignments should start (e.g., `mg-contoso`).
-   **Environment**: `live` (or your target environment).
-   **Location**: The Azure region for the deployment metadata.

### 3. Verify Assignments

After the `Deploy` stage completes:
1.  Go to the **Azure Portal**.
2.  Navigate to **Management Groups**.
3.  Select the target group.
4.  Click **Access control (IAM)** -> **Role assignments**.
5.  Verify your new assignments appear in the list.

## Troubleshooting

### `AuthorizationFailed` Error

**Symptom**: The pipeline fails with an authorization error.
**Cause**: The deployment Service Principal does not have permission to assign roles.
**Fix**: Grant `User Access Administrator` or `Owner` to the Service Principal at the Management Group scope.

### `RoleAssignmentExists` Error

**Symptom**: Deployment fails stating the assignment already exists.
**Cause**: Bicep usually handles idempotency, but if the ID generation logic differs or if there's a conflict with a manual assignment.
**Fix**: Ensure the `name` property in Bicep is deterministically generated based on Scope + Principal + Role (which it is in our template). Check if a manual assignment conflicts.
