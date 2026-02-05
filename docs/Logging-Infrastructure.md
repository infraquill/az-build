# Logging Infrastructure

This section provides comprehensive documentation for deploying and managing the centralized logging infrastructure in Azure.

## Overview

The Logging Infrastructure provides the foundation for audit and security logging by deploying a centralized Log Analytics Workspace and Automation Account. It is deployed as a foundational component before other monitoring services.

## Documentation Structure

- [Logging Infrastructure Overview](Logging-Infrastructure/Logging-Infrastructure-Overview.md) - Learn about the architecture and components
- [Deploying Logging Infrastructure](Logging-Infrastructure/Deploying-Logging-Infrastructure.md) - Step-by-step deployment guide
- [Managing Logging Infrastructure](Logging-Infrastructure/Managing-Logging-Infrastructure.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/logging/logging.bicep`
- **Parameters File**: `code/bicep/logging/logging.bicepparam`
- **Pipeline**: `code/pipelines/logging/logging-pipeline.yaml`

## Key Concepts

- **Log Analytics Workspace**: Central repository for logs and metrics
- **Automation Account**: Linked service for process automation
- **Deployment Stack**: Locked deployment for critical infrastructure stability
