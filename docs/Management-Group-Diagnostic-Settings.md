# Management Group Diagnostic Settings

This section provides comprehensive documentation for configuring diagnostic settings across the Management Group hierarchy.

## Overview

User Management Group Diagnostic Settings ensure that Activity Logs and other governance-related logs from the Management Group hierarchy are automatically sent to the centralized Log Analytics Workspace. This is crucial for security visibility and compliance auditing.

## Documentation Structure

- [Management Group Diagnostic Settings Overview](Management-Group-Diagnostic-Settings/Management-Group-Diagnostic-Settings-Overview.md) - Learn about the architecture and logs
- [Deploying Diagnostic Settings](Management-Group-Diagnostic-Settings/Deploying-Management-Group-Diagnostic-Settings.md) - Step-by-step deployment guide
- [Managing Diagnostic Settings](Management-Group-Diagnostic-Settings/Managing-Management-Group-Diagnostic-Settings.md) - Best practices for log management

## Quick Links

- **Bicep Template**: `code/bicep/mg-diag-settings/mg-diag-settings.bicep`
- **Pipeline**: `code/pipelines/mg-diag-settings/mg-diag-settings-pipeline.yaml`
- **Module**: `code/bicep/mg-diag-settings/modules/diagnostic-setting.bicep`

## Key Concepts

- **Activity Logs**: detailed records of create, update, and delete operations on resources
- **Diagnostic Settings**: Configuration that defines where platform logs and metrics are sent
- **Centralization**: Aggregating logs to a single workspace for correlation and security analysis
- **Hierarchy Compliance**: Ensures that every management group in the hierarchy (Root, Platform, Landing Zones) captures audit data
