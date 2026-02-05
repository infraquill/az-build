# Logging Infrastructure Overview

## Introduction

The Logging Infrastructure provides the centralized foundation for observability, security, and audit logging across the Azure environment. It deploys the primary Log Analytics Workspace that collects data from all subscriptions and management groups.

## Architecture

```
Management Subscription
└── Resource Group (rg-logging-live-cac-01)
    ├── Log Analytics Workspace (law-logging-live-cac-01)
    │   ├── SKU: PerGB2018
    │   └── Retention: 60 days (configurable)
    │
    └── Automation Account (aa-logging-live-cac-01)
        └── Linked to Workspace (for updates/change tracking)
```

## Setup Sequence

This module is deployed early in the **Platform Infrastructure** phase, typically **Step 3**, immediately after Governance. It must exist before:
1.  **Diagnostic Settings** can be configured (they need a destination).
2.  **Hub Networking** updates (if using Diagnostic Settings for Firewall/VNet).
3.  **Workloads** are deployed (they need a place to send logs).

## Key Components

### Log Analytics Workspace
The central data lake for Azure Monitor. All logs (Activity Logs, Metrics, Diagnostic Logs) are forwarded here.

### Automation Account
Provides process automation and configuration management capabilities. It is linked to the workspace to enable solutions like Update Management.

## Default Configuration

| Component | Setting | Default Value | Notes |
|-----------|---------|---------------|-------|
| Workspace | SKU | `PerGB2018` | Standard pay-as-you-go pricing |
| Workspace | Retention | `60` days | Can be increased up to 730 days |
| Workspace | Location | `canadacentral` | Should match data residency requirements |
