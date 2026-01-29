# Monitoring Infrastructure Overview

## Introduction

The monitoring infrastructure provides a centralized Log Analytics workspace that serves as the primary destination for logs, metrics, and diagnostic data from Azure resources. This infrastructure is deployed using Azure Verified Modules (AVM) and managed through Azure Deployment Stacks.

## Architecture

```
Monitoring Subscription
└── Resource Group: rg-monitoring-<env>-<loc>-<instance>
    └── Log Analytics Workspace: law-monitoring-<env>-<loc>-<instance>
```

### Components

| Component | Description |
|-----------|-------------|
| Resource Group | Container for monitoring resources, tagged for ownership and management |
| Log Analytics Workspace | Central log and metric repository with configurable retention |

## Naming Convention

Resources follow a consistent naming convention:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-<workloadAlias>-<env>-<loc>-<instance>` | `rg-monitoring-live-cac-001` |
| Log Analytics Workspace | `law-<workloadAlias>-<env>-<loc>-<instance>` | `law-monitoring-live-cac-001` |

### Naming Components

- **workloadAlias**: The workload alias for naming (e.g., `monitoring`, `hub`)
- **env**: Environment identifier (e.g., `live`, `nonprod`, `dev`)
- **loc**: Location code (e.g., `cac` for Canada Central)
- **instance**: Instance number (e.g., `001`)

## Features

### Log Analytics Workspace

- **Centralized Logging**: Collect logs from all Azure resources
- **Configurable Retention**: Data retention from 30 to 730 days
- **Query Capabilities**: Use Kusto Query Language (KQL) for analysis
- **Integration**: Works with Azure Monitor, Azure Sentinel, and other services

### Deployment Stack Protection

The infrastructure is deployed as a Deployment Stack, providing:

- **Deny Settings**: Prevent unauthorized modifications
- **Managed Resources**: Track all resources in the stack
- **Unmanage Actions**: Control what happens when resources are removed from the template

## Default Configuration

The default deployment creates:

| Parameter | Default Value |
|-----------|---------------|
| Workload Alias | `monitoring` |
| Environment | `live` |
| Location | `canadacentral` |
| Location Code | `cac` |
| Instance Number | `001` |
| Data Retention | 60 days |
| Managed By | `Bicep` |

## Azure Verified Module

The Log Analytics workspace is deployed using the AVM module:

```bicep
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.0' = {
  // ...
}
```

This module provides:
- Best-practice configuration
- Consistent deployment patterns
- Microsoft-validated implementation

## Integration Points

### Diagnostic Settings

Configure Azure resources to send logs and metrics to the Log Analytics workspace:

```
Azure Resource
└── Diagnostic Settings
    └── Log Analytics Workspace (destination)
```

### Azure Monitor

The workspace integrates with Azure Monitor for:
- Alerts and action groups
- Workbooks and dashboards
- Application Insights
- Container Insights

### Azure Sentinel

For security monitoring, the workspace can be onboarded to Azure Sentinel.

## Next Steps

- [Deploying Monitoring Infrastructure](Deploying-Monitoring-Infrastructure.md) - Learn how to deploy
- [Managing Monitoring Infrastructure](Managing-Monitoring-Infrastructure.md) - Ongoing management
