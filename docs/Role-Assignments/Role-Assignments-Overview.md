# Role Assignments Overview

## Introduction

The Role Assignments infrastructure allows you to centrally manage access control for your Azure environment. By assigning roles at the Management Group scope, you ensure consistent access rights across all subscriptions and resources within that hierarchy.

## Architecture

```
Management Group Hierarchy
└── Target Management Group (e.g., mg-platform)
    └── Role Assignment
        ├── Principal: Group or User (e.g., Platform Team)
        ├── Role: Owner / Contributor / NetOps
        └── Inheritance: Applies to all child resources
```

## Strategy

We recommend a **Group-based** strategy for RBAC:

1.  **Create AD Security Groups** for your functions (e.g., `Platform-Admins`, `NetOps-Team`).
2.  **Add Users to Groups**: Manage membership in Azure AD (Entra ID).
3.  **Assign Roles to Groups**: Use this infrastructure to assign the Role to the Group.

This approach minimizes churn in your Infrastructure-as-Code. You don't need to run a deployment to add a new team member; you just add them to the group in AD.

## Components

### Role Assignment

Each assignment consists of:

| Property | Description |
|----------|-------------|
| **Principal ID** | The Object ID of the AD Group, User, or Service Principal |
| **Role Definition ID** | The ID of the Role (Built-in or Custom) to assign |
| **Principal Type** | Usually `Group` (recommended) or `ServicePrincipal` |
| **Description** | Human-readable explanation of the assignment |

## Integration Points

### Management Group Hierarchy

Assignments are typically made at the following levels:

-   **Intermediate Root** (`mg-landing-zones`): Assign `Reader` to auditing teams.
-   **Platform MG** (`mg-platform`): Assign `Owner` to the Platform Engineering team.
-   **Landing Zone MGs**: Assign specific workload owners.

### Custom Roles

This module pairs well with the **Role Definitions** module. You can first define a custom role (e.g., `NetOps`) and then use this module to assign it.

## Prerequisites

1.  **Service Principal Permissions**: The deployment SPN needs `Owner` or `User Access Administrator` permissions on the target scope to create role assignments.
2.  **Role Definitions**: If using custom roles, they must be deployed first.
