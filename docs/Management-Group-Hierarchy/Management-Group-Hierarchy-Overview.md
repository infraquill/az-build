# Management Group Hierarchy Overview

## Introduction

The Management Group hierarchy is a fundamental component of Azure governance and organization. It provides a way to efficiently manage access, policies, and compliance across multiple Azure subscriptions.

## Hierarchy Structure

The default management group hierarchy follows a well-established pattern:

```
Tenant Root Management Group
└── Organization Root (org-name)
    ├── Platform
    │   ├── Management
    │   └── Connectivity
    ├── Landing Zone
    │   ├── Corp Production
    │   ├── Corp Non-Production
    │   ├── Online Production
    │   └── Online Non-Production
    ├── Sandbox
    └── Decommissioned
```

## Management Group Purposes

### Organization Root
- **Purpose**: Top-level management group for your organization
- **Parent**: Tenant Root Management Group
- **Use Case**: Apply organization-wide policies and governance

### Platform
- **Purpose**: Management group for platform-level services and infrastructure
- **Parent**: Organization Root
- **Use Case**: Centralized platform services that support all workloads

#### Management (Child of Platform)
- **Purpose**: Management and monitoring services
- **Use Case**: Log Analytics workspaces, Automation accounts, monitoring solutions

#### Connectivity (Child of Platform)
- **Purpose**: Network connectivity services
- **Use Case**: Virtual WAN, ExpressRoute, VPN gateways, hub networks

### Landing Zone
- **Purpose**: Management group for application workloads
- **Parent**: Organization Root
- **Use Case**: Production and non-production application environments

#### Corp Production / Non-Production
- **Purpose**: Corporate/internal application workloads
- **Use Case**: Internal business applications, line-of-business systems

#### Online Production / Non-Production
- **Purpose**: Customer-facing application workloads
- **Use Case**: Public-facing applications, web services, APIs

### Sandbox
- **Purpose**: Experimental and testing environments
- **Parent**: Organization Root
- **Use Case**: Proof of concepts, experimentation, learning

### Decommissioned
- **Purpose**: Resources being retired or decommissioned
- **Parent**: Organization Root
- **Use Case**: Temporary holding area for resources being removed

## Key Benefits

1. **Centralized Governance**: Apply policies and compliance standards at scale
2. **Access Management**: Control access using Azure RBAC at the management group level
3. **Cost Management**: Organize subscriptions for cost allocation and reporting
4. **Compliance**: Enforce regulatory requirements consistently
5. **Scalability**: Support hundreds of subscriptions efficiently

## Implementation Details

The management group hierarchy is implemented using:
- **Bicep Template**: Infrastructure as Code definition
- **Azure Bicep Registry Module**: Uses the AVM (Azure Verified Modules) management group module
- **Sequential Deployment**: Management groups are deployed sequentially to ensure parent groups exist before children

## Next Steps

- [Creating Management Group Hierarchy](Creating-Management-Group-Hierarchy.md) - Learn how to create your hierarchy
- [Managing Management Group Hierarchy](Managing-Management-Group-Hierarchy.md) - Understand ongoing management
