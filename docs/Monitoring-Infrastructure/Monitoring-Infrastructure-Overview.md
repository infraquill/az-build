# Monitoring Infrastructure Overview

## Introduction

The Monitoring Infrastructure focuses on **observability and alerting**. Unlike the Logging Infrastructure (which *collects* the data), this module *consumes* the centralized Log Analytics Workspace to deploy Action Groups and Alert Rules.

## Architecture

```
Management Subscription
└── Resource Group (rg-monitoring-<env>-<loc>-<instance>)
    ├── Action Group (ag-platform-team)
    │   └── Email Receiver: platform-team@contoso.com
    │
    └── Alert Rules
        ├── ServiceHealth Alert
        ├── Azure Monitor Baseline Alerts (AMBA)
        └── Custom Metric Alerts
```

## Setup Sequence

This module is deployed **after Logging Infrastructure** because it depends on the workspace ID to query for alert conditions.

## Key Components

### Action Groups
Collections of notification preferences. When an alert triggers, it notifies the Action Group, which can send emails, SMS, or trigger Webhooks/Functions.

### Alert Rules
Logic that queries the Log Analytics Workspace or Azure Resource Health.
-   **Service Health**: Notifications about Azure region outages.
-   **Log Alerts**: Queries KQL against the workspace (e.g., "Heartbeat missing").
-   **Metric Alerts**: Threshold breaches (e.g., "CPU > 90%").

## Default Configuration

| Component | Default Value | Notes |
|-----------|---------------|-------|
| Action Group Short Name | `Platform` | Limited to 12 chars |
| Email Receiver | `platform-team@arcnovus.net` | Configurable via param |
