# Monitoring Infrastructure

This section provides comprehensive documentation for deploying and managing the centralized monitoring infrastructure in Azure.

## Overview

The monitoring infrastructure provides a centralized Log Analytics workspace for collecting and analyzing logs, metrics, and diagnostic data from Azure resources across your environment. It uses Azure Deployment Stacks for protected, managed deployments.

## Documentation Structure

- [Monitoring Infrastructure Overview](Monitoring-Infrastructure/Monitoring-Infrastructure-Overview.md) - Learn about the architecture and components
- [Deploying Monitoring Infrastructure](Monitoring-Infrastructure/Deploying-Monitoring-Infrastructure.md) - Step-by-step deployment guide
- [Managing Monitoring Infrastructure](Monitoring-Infrastructure/Managing-Monitoring-Infrastructure.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/monitoring/monitoring.bicep`
- **Parameters File**: `code/bicep/monitoring/monitoring.bicepparam`
- **Pipeline**: `code/pipelines/monitoring-pipeline.yaml`

## Key Concepts

- **Log Analytics Workspace**: Central repository for logs and metrics from Azure resources
- **Deployment Stack**: Azure deployment mechanism providing protection against accidental deletion and modification
- **Deny Settings**: Controls that prevent unauthorized changes to managed resources
- **Azure Verified Modules (AVM)**: Pre-built, tested Bicep modules from Microsoft
