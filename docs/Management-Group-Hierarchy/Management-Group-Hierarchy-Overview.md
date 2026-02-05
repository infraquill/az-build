# Management Group Hierarchy Overview

## Introduction

The Management Group hierarchy is a fundamental component of Azure governance and organization. It provides a way to efficiently manage access, policies, and compliance across multiple Azure subscriptions.

## Hierarchy Structure

The management group hierarchy follows the **Regular / High Compliance** pattern, which includes explicit separation of production and non-production environments to enforce strict security boundaries.

```
Tenant Root Management Group
└── Organization Root (mg-org)
    ├── Platform (mg-platform)
    │   ├── Identity (mg-identity)
    │   ├── Management (mg-management)
    │   └── Connectivity (mg-connectivity)
    ├── Landing Zones (mg-landing-zones)
    │   ├── Corp (mg-corp)
    │   │   ├── Corp Production (mg-corp-prod)
    │   │   └── Corp Non-Production (mg-corp-non-prod)
    │   └── Online (mg-online)
    │       ├── Online Production (mg-online-prod)
    │       └── Online Non-Production (mg-online-non-prod)
    ├── Sandbox (mg-sandbox)
    └── Decommissioned (mg-decommissioned)
```

## Compliance & Security Context

This hierarchy is designed for **Canadian Nuclear / PBMM** compliance standards, requiring strict separation between Production and Non-Production environments.

### Why Split Prod and Non-Prod?
In high-security industries, simply tagging subscriptions is insufficient. Explicit Management Group boundaries allow for:
1.  **Distinct IAM Models**: "No standing access" in Production vs "Contributor access" in Non-Prod.
2.  **Data Classification Enclave**: `mg-corp-prod` is designated for **Protected B** data, while `mg-corp-non-prod` is for Unclassified/Protected A.
3.  **Divergent Policies**: Enforce strict backups/retention in Prod, while allowing cost-saving configurations in Non-Prod.

## Naming Convention & ID Table

The following table defines the standard naming convention for the hierarchy. We prioritize **readability** and **uniqueness**.

| Hierarchy Level | Resource ID | Display Name | Purpose |
|-----------------|-------------|--------------|---------|
| **Root** | `mg-org` | *Organization Name* | The root governance boundary for the organization. |
| **Platform** | `mg-platform` | Platform | Container for centralized platform services. |
| | `mg-identity` | Identity | Domain controllers, Azure AD Connect, Identity policies. |
| | `mg-management` | Management | Centralized monitoring (Log Analytics), Key Vaults, Automation. |
| | `mg-connectivity` | Connectivity | Hub VNet, ExpressRoute/VPN, DNS, Firewall. |
| **Landing Zones** | `mg-landing-zones` | Landing Zones | Container for all application workloads. |
| | `mg-corp` | Corp | Internal/Hybrid workloads (connected to Hub). |
| | ...`mg-corp-prod` | Corp Production | **Protected B**. Strict IAM/Policy. |
| | ...`mg-corp-non-prod` | Corp Non-Prod | **Unclassified**. Dev/Test access allowed. |
| | `mg-online` | Online | Public-facing workloads (DMZ-style). |
| | ...`mg-online-prod` | Online Production | **Protected B**. Strict IAM/Policy. |
| | ...`mg-online-non-prod` | Online Non-Prod | **Unclassified**. Dev/Test access allowed. |
| **Sandbox** | `mg-sandbox` | Sandbox | Isolated environment for experimentation. |
| **Decommissioned** | `mg-decommissioned` | Decommissioned | Holding area for subscriptions before cancellation/deletion. |

## Management Group Purposes

### Organization Root (`mg-org`)
- **Parent**: Tenant Root Management Group
- **Use Case**: Top-level container for all organizational resources. Apply organization-wide policies (e.g., allowed locations) here.

### Platform (`mg-platform`)
- **Parent**: Organization Root
- **Use Case**: Hosts the shared services required by the entire organization.
- **Children**:
  - **Identity**: Dedicated to identity management resources (avoiding circular dependencies).
  - **Management**: Centralized logging, monitoring, and automation.
  - **Connectivity**: The network hub (Hub VNet, Firewalls, Gateways).

### Landing Zones (`mg-landing-zones`)
- **Parent**: Organization Root
- **Use Case**: The home for all application workloads.
- **Children**:
  - **Corp**: For "Corporate" applications (Hybrid).
    - **Corp Prod (`mg-corp-prod`)**: Protected B data. Strict access control.
    - **Corp Non-Prod (`mg-corp-non-prod`)**: Unclassified. Developer access allowed.
  - **Online**: For "Online" applications (Internet-facing).
    - **Online Prod (`mg-online-prod`)**: Protected B data. Strict access control.
    - **Online Non-Prod (`mg-online-non-prod`)**: Unclassified. Developer access allowed.

### Sandbox (`mg-sandbox`)
- **Parent**: Organization Root
- **Use Case**: A safe place for experimentation. Policies here are less restrictive to allow learning, but strict cost controls are often applied.

### Decommissioned (`mg-decommissioned`)
- **Parent**: Organization Root
- **Use Case**: A holding area for subscriptions that are no longer in use, prior to being deleted. This ensures they are stripped of normal access and policies during the winding-down phase.

## Key Benefits

1. **Centralized Governance**: Apply policies and compliance standards at scale.
2. **Access Management**: Control access using Azure RBAC at the management group level.
3. **Cost Management**: Organize subscriptions for cost allocation and reporting.
4. **Compliance**: Enforce regulatory requirements consistently.
5. **Scalability**: Support hundreds of subscriptions efficiently.

## Implementation Details

The management group hierarchy is implemented using:
- **Bicep Template**: Defined in `code/bicep/mg-hierarchy/mg-hierarchy.bicep`.
- **Custom Resource Loop**: Implements the structure via a parameter-driven loop for maximum flexibility.
- **Sequential Deployment**: Management groups are deployed sequentially to ensure parent groups exist before children.

## Next Steps

- [Creating Management Group Hierarchy](Creating-Management-Group-Hierarchy.md) - Learn how to create your hierarchy
- [Managing Management Group Hierarchy](Managing-Management-Group-Hierarchy.md) - Understand ongoing management
