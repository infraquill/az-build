# Azure Build Foundation

> **⚠️ Disclaimer: Personal Reference Project**
> 
> This repository is a **personal and opinionated project** created for my own use and learning. It is **not intended for production use** and should **not be relied upon** to build your Azure environment without significant review, customization, and testing.
> 
> **Important Notes:**
> - This project is **subject to change** at any time without notice
> - It reflects my personal preferences and may not align with your organization's requirements or best practices
> - It is **not maintained** for general public use or production scenarios
> - While made publicly available, it is **not designed to be reusable** by the general population
> 
> **You are responsible for:**
> - Reviewing all code and configurations before use
> - Testing thoroughly in non-production environments
> - Customizing to meet your specific requirements
> - Ensuring compliance with your organization's policies and standards
> - Understanding the security and operational implications of any deployment

---

A personal Azure infrastructure foundation using Bicep templates and Azure DevOps pipelines. This project demonstrates a structured approach to deploying Azure environments following Azure Landing Zone patterns, leveraging Azure Verified Modules (AVM) and Cloud Adoption Framework (CAF) best practices.

## Structure

### Infrastructure as Code (`code/bicep/`)
- **mg-hierarchy/** - Management group structure
- **policy-definitions/** - Custom Azure Policy definitions
- **role-definitions/** - Custom RBAC role definitions
- **logging/** - Central Log Analytics and Automation Account
- **mg-diag-settings/** - Management Group diagnostic settings
- **monitoring/** - Alerting and observability (Action Groups, Alerts)
- **hub/** - Hub networking (VNet, Firewall, Gateway)
- **role-assignments/** - RBAC assignments for Management Groups
- **governance/** - Policy assignments (MCSB, PBMM)
- **sub-vending/** - Subscription provisioning
- **spoke/** - Spoke networking infrastructure
- **cloudops/** - Operational tooling (DevOps agents)

### CI/CD Pipelines (`code/pipelines/`)
Every Bicep module above has a corresponding Azure DevOps pipeline in `code/pipelines/<module-name>/`.

## Getting Started

**⚠️ Example Use Only. Review, test, and customize everything before use.**

1. **Review the codebase** - Understand the structure, patterns, and implementation details
2. **Clone and customize** - Adapt the Bicep templates in `code/bicep/` to your specific requirements
3. **Configure pipelines** - Modify the pipelines in `code/pipelines/` for your Azure DevOps environment
4. **Test thoroughly** - Deploy and test in non-production environments first

## Documentation

**Start Here: [Deployment Overview](docs/Overview.md)** - Complete 12-step deployment flow and architecture.

### Core Components
- [Management Group Hierarchy](docs/Management-Group-Hierarchy.md)
- [Policy Definitions](docs/Overview.md#step-2-policy-definitions)
- [Role Definitions](docs/Overview.md#step-3-role-definitions)
- [Logging Infrastructure](docs/Logging-Infrastructure.md)
- [Diagnostic Settings](docs/Management-Group-Diagnostic-Settings.md)
- [Monitoring Infrastructure](docs/Monitoring-Infrastructure.md)
- [Role Assignments](docs/Role-Assignments.md)

### Networking & Operations
- [Hub Infrastructure](docs/Hub-Infrastructure.md)
- [Spoke Infrastructure](docs/Spoke-Infrastructure.md)
- [Subscription Vending](docs/Subscription-Vending.md)
- [CloudOps](docs/CloudOps.md)
- [Governance](docs/Governance.md)

### Reference
- [RBAC Requirements](docs/RBAC-Requirements.md)

## Deployment Sequence

**Phase 1: Foundation**
1.  Management Group Hierarchy
2.  Policy Definitions
3.  Role Definitions
4.  Logging Infrastructure
5.  Management Group Diagnostic Settings

**Phase 2: Platform Infrastructure**
6.  Monitoring Infrastructure (Alerts)
7.  Hub Infrastructure
8.  Role Assignments

**Phase 3: Workload Infrastructure**
9.  Subscription Vending
10. Spoke Networking
11. CloudOps (First Workload)
12. Governance (Policy Assignments)

See **[docs/Overview.md](docs/Overview.md)** for the detailed guide.