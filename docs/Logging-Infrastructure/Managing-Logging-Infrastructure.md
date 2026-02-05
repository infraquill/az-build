# Managing Logging Infrastructure

## Ongoing Management

### Changing Data Retention

To increase or decrease log retention:
1.  Open `code/bicep/logging/logging.bicepparam`.
2.  Update the `dataRetention` parameter (e.g., from `60` to `90`).
3.  Commit and run the pipeline.

### Upgrading SKU

If you need to switch to a Capacity Reservation tier:
1.  Update `workspaceSku` in the bicepparam file.
2.  **Note**: Ensure you meet the minimum daily ingestion requirements for Capacity Reservation tiers before switching.

## Security Best Practices

-   **Access Control**: Restrict access to the Log Analytics Workspace. Use **Log Analytics Reader** for users who only need to query logs.
-   **Locking**: The Deployment Stack automatically protects the workspace from accidental deletion (`DenyWriteAndDelete` mode).
