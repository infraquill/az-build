# Governance Overview

## Introduction

The governance infrastructure deploys Azure Policy assignments at the management group level to assess compliance with security benchmarks and regulatory standards. This enables consistent compliance visibility across all subscriptions within the management group hierarchy.

Policies are assigned in **audit mode** (`DoNotEnforce`) and are intended to remain that way. This design philosophy uses Azure Policy as a **reporting and compliance assessment mechanism** rather than an enforcement or remediation tool.

## Design Philosophy: Audit-Only Policies

> **Recommendation:** Keep policies in audit-only mode permanently. Use IaC (Bicep templates and pipelines) to implement and remediate configurations.

### Why Audit-Only?

| Benefit | Description |
|---------|-------------|
| **Centralized Control** | All infrastructure changes flow through IaC pipelines with proper review and approval |
| **Prevents Drift** | Policy remediation tasks can make changes outside of IaC, causing configuration drift |
| **Predictable Changes** | Infrastructure changes are explicit, versioned, and traceable in source control |
| **No Unexpected Modifications** | Policy remediation can modify resources at any time without warning |
| **Clear Ownership** | IaC pipelines are the single source of truth for infrastructure configuration |

### Recommended Workflow

1. **Deploy policies** in audit mode (`DoNotEnforce`)
2. **Monitor compliance** using Azure Policy dashboards and reports
3. **Identify gaps** through compliance data and non-compliant resource reports
4. **Remediate via IaC** by updating Bicep templates to meet compliance requirements
5. **Deploy changes** through standard IaC pipelines with review and approval

## Architecture

```
Management Group Hierarchy
└── Target Management Group (e.g., mg-platform)
    ├── Policy Assignment: Microsoft Cloud Security Benchmark (MCSB)
    │   ├── Mode: Audit (DoNotEnforce)
    │   └── Managed Identity: SystemAssigned
    │
    └── Policy Assignment: Canada Federal PBMM
        ├── Mode: Audit (DoNotEnforce)
        └── Managed Identity: SystemAssigned
```

## Policy Initiatives

### Microsoft Cloud Security Benchmark (MCSB)

The Microsoft Cloud Security Benchmark provides prescriptive best practices and recommendations to help improve the security of workloads, data, and services on Azure.

**Key Areas:**
- Network Security
- Identity Management
- Privileged Access
- Data Protection
- Asset Management
- Logging and Threat Detection
- Incident Response
- Posture and Vulnerability Management
- Endpoint Security
- Backup and Recovery
- DevOps Security
- Governance and Strategy

**Initiative ID:** `/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8`

**Assignment Name Pattern:** `mcsb-audit-<environment>`

### Canada Federal PBMM

The Canada Federal Protected B / Medium Integrity / Medium Availability (PBMM) policy initiative helps address compliance requirements for Canadian federal government workloads.

**Key Areas:**
- Access Control
- Audit and Accountability
- Security Assessment and Authorization
- Configuration Management
- Contingency Planning
- Identification and Authentication
- Incident Response
- Maintenance
- Media Protection
- Physical and Environmental Protection
- Planning
- Personnel Security
- Risk Assessment
- System and Services Acquisition
- System and Communications Protection
- System and Information Integrity

**Initiative ID:** `/providers/Microsoft.Authorization/policySetDefinitions/4c4a5f27-de81-430b-b4e5-9cbd50595a87`

**Assignment Name Pattern:** `canada-pbmm-audit-<environment>`

## Components

### Policy Assignments

Each policy assignment includes:

| Property | Description |
|----------|-------------|
| **Name** | Unique identifier (e.g., `mcsb-audit-live`) |
| **Display Name** | Human-readable name shown in Azure Portal |
| **Description** | Detailed description of the assignment purpose |
| **Policy Definition ID** | Reference to the policy initiative |
| **Enforcement Mode** | `DoNotEnforce` (audit) or `Default` (enforce) |
| **Managed Identity** | System-assigned identity for remediation |
| **Metadata** | Tags including environment, owner, and managed-by |
| **Non-Compliance Messages** | Custom messages shown for non-compliant resources |

### Managed Identities

Each policy assignment creates a system-assigned managed identity. These identities exist to support Azure's policy remediation feature.

> **Note:** While managed identities are created, **we recommend NOT using policy remediation tasks**. Instead, use IaC pipelines to make infrastructure changes. This keeps all modifications centralized, traceable, and under version control. See [Design Philosophy: Audit-Only Policies](#design-philosophy-audit-only-policies) for details.

## Enforcement Modes

| Mode | Value | Behavior |
|------|-------|----------|
| **Audit** | `DoNotEnforce` | Evaluates compliance but doesn't block non-compliant resources |
| **Enforce** | `Default` | Blocks creation of non-compliant resources and can deny modifications |

**Recommended Approach:**

> **Keep policies in audit mode (`DoNotEnforce`) permanently.**

Using audit mode provides:
- Visibility into compliance posture across all resources
- Data for security reporting and dashboards
- Input to Microsoft Defender for Cloud secure score
- Compliance evidence for audits and certifications

Avoid using `Default` (enforcement) mode because:
- It can block legitimate deployments unexpectedly
- Policy evaluation timing can cause race conditions with IaC deployments
- Enforcement bypasses IaC pipelines and approval workflows
- It creates friction for development teams without adding security value beyond audit

## Target Management Groups

The governance pipeline can target any management group in your hierarchy:

| Management Group | Typical Use Case |
|------------------|------------------|
| `mg-platform` | Apply to all platform subscriptions |
| `mg-landing-zone` | Apply to all landing zone subscriptions |
| `mg-corp-prod` | Apply to production corporate workloads |
| `mg-corp-non-prod` | Apply to non-production corporate workloads |
| `mg-online-prod` | Apply to production online workloads |
| `mg-online-non-prod` | Apply to non-production online workloads |
| Tenant Root | Apply to entire tenant (use with caution) |

> **Best Practice:** Start by applying policies at lower-level management groups (e.g., `mg-corp-non-prod`) before rolling out to production and higher-level groups.

## Naming Convention

Resources follow a consistent naming convention:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| MCSB Assignment | `mcsb-audit-<env>` | `mcsb-audit-live` |
| Canada PBMM Assignment | `canada-pbmm-audit-<env>` | `canada-pbmm-audit-live` |

### Naming Components

- **env**: Environment identifier (e.g., `live`, `nonprod`, `dev`)

## Integration Points

### Management Group Hierarchy

The governance policies integrate with the management group hierarchy:

- Policies inherit down through the hierarchy
- Child management groups and subscriptions automatically receive policy assignments
- Exemptions can be applied at any level to exclude specific resources

### Azure Policy Compliance

After deployment, compliance data flows to:

- **Azure Policy Dashboard**: View compliance state across all resources
- **Microsoft Defender for Cloud**: Security recommendations and secure score
- **Azure Resource Graph**: Query compliance data programmatically

### Monitoring

Policy compliance events can be monitored through:

- Azure Policy compliance reports
- Activity Log events for policy evaluations
- Azure Monitor alerts for compliance state changes

## Default Configuration

The default deployment creates:

| Parameter | Default Value |
|-----------|---------------|
| Environment | `live` |
| Location | `canadacentral` |
| Enforcement Mode | `DoNotEnforce` |
| Enable MCSB | `true` |
| Enable Canada PBMM | `true` |
| Managed By | `Bicep` |

## Prerequisites

Before deploying governance policies, ensure:

1. **Management Group Hierarchy**: The target management group must exist
2. **Service Principal Permissions**: See [RBAC Requirements](../RBAC-Requirements.md) for required roles
3. **Azure DevOps Pipeline**: Configured with appropriate service connection

## Next Steps

- [Deploying Governance](Deploying-Governance.md) - Learn how to deploy
- [Managing Governance](Managing-Governance.md) - Compliance monitoring and IaC-driven remediation
