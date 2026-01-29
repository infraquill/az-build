# Governance

This section provides comprehensive documentation for deploying and managing Azure Policy assignments for compliance and security governance across your Azure environment.

## Overview

The governance infrastructure deploys Azure Policy assignments at the management group level to assess compliance with security benchmarks and regulatory standards. Policies are assigned in **audit mode** (`DoNotEnforce`) and are intended to remain that way permanently.

> **Design Philosophy:** Use Azure Policy as a **reporting mechanism** to identify compliance gaps. Remediation should be performed through IaC pipelines, not through policy remediation tasks. This keeps all infrastructure changes centralized, traceable, and prevents configuration drift.

## Documentation Structure

- [Governance Overview](Governance/Governance-Overview.md) - Learn about the policies, architecture, and components
- [Deploying Governance](Governance/Deploying-Governance.md) - Step-by-step deployment guide
- [Managing Governance](Governance/Managing-Governance.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/governance/governance.bicep`
- **Parameters File**: `code/bicep/governance/governance.bicepparam`
- **Pipeline**: `code/pipelines/governance/governance-pipeline.yaml`

## Key Concepts

- **Azure Policy**: Azure service that assesses compliance at scale—used here for reporting, not enforcement
- **Policy Initiative**: A collection of related policy definitions grouped together (e.g., Microsoft Cloud Security Benchmark)
- **Policy Assignment**: The application of a policy or initiative to a specific scope (management group, subscription, resource group)
- **Audit Mode**: Policies evaluate compliance without blocking resources (`DoNotEnforce`)—the recommended permanent state
- **IaC-Driven Remediation**: Fix compliance gaps by updating Bicep templates and deploying through pipelines
