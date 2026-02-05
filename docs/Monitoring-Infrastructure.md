# Monitoring Infrastructure

This section provides comprehensive documentation for deploying and managing the alerting and observability layer of the platform.

## Overview

The Monitoring Infrastructure focuses on **observability and alerting**. It connects to the centralized Log Analytics Workspace and deploys Action Groups and Alert Rules to monitor the health of the platform foundation.

## Documentation Structure

- [Monitoring Infrastructure Overview](Monitoring-Infrastructure/Monitoring-Infrastructure-Overview.md) - Learn about alerts and action groups
- [Deploying Monitoring Infrastructure](Monitoring-Infrastructure/Deploying-Monitoring-Infrastructure.md) - Step-by-step deployment guide
- [Managing Monitoring Infrastructure](Monitoring-Infrastructure/Managing-Monitoring-Infrastructure.md) - Adding alerts and updating contacts

## Quick Links

- **Bicep Template**: `code/bicep/monitoring/monitoring.bicep`
- **Parameters File**: `code/bicep/monitoring/monitoring.bicepparam`
- **Pipeline**: `code/pipelines/monitoring/monitoring-pipeline.yaml`

## Related Components

- [Logging Infrastructure](Logging-Infrastructure.md) - Centralized Log Analytics Workspace
- [Management Group Diagnostic Settings](Management-Group-Diagnostic-Settings.md) - Log forwarding configuration

## Key Concepts

- **Action Group**: A collection of notification preferences (Email, SMS) defined by the owner
- **Alert Rules**: Metric and log-based alerts to monitor workspace health and data ingestion
- **Smart Detection**: Automatically detects anomalies in application performance
- **Deployment Stack**: Azure deployment mechanism providing protection against accidental deletion
