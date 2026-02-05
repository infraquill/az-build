# Management Group Diagnostic Settings Overview

## Introduction

Management Group Diagnostic Settings ensure that Activity Logs and other governance-related logs from the Management Group hierarchy are automatically sent to the centralized Log Analytics Workspace. This provides visibility into "who did what, when" at the governance level.

## Architecture

```
Management Group Hierarchy
└── Root / Intermediate MG
    └── Diagnostic Setting
        └── Destination: Log Analytics Workspace (Central)
        └── Logs:
            ├── Administrative
            ├── Security
            ├── ServiceHealth
            ├── Alert
            ├── Recommendation
            ├── Policy
            ├── Autoscale
            └── ResourceHealth
```

## Setup Sequence

This module is deployed **after Logging Infrastructure** (Step 3) because it depends on the Log Analytics Workspace Resource ID.

## Key Components

### Diagnostic Setting
A configuration resource that defines:
1.  **What to log**: Activity Logs, Metrics.
2.  **Where to send it**: Log Analytics Workspace, Storage Account, Event Hub.

### Activity Logs
Insight into subscription-level events that have occurred in Azure. This includes data ranging from ARM operational data to updates on Service Health events.
