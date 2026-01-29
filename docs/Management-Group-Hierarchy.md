# Management Group Hierarchy

This section provides comprehensive documentation for creating and managing the Azure Management Group hierarchy in your organization.

## Overview

The Management Group hierarchy provides a way to organize and manage Azure subscriptions at scale. It enables you to apply governance policies, access controls, and compliance standards consistently across multiple subscriptions.

## Documentation Structure

- [Management Group Hierarchy Overview](Management-Group-Hierarchy/Management-Group-Hierarchy-Overview.md) - Learn about the structure and purpose of the management group hierarchy
- [Creating Management Group Hierarchy](Management-Group-Hierarchy/Creating-Management-Group-Hierarchy.md) - Step-by-step guide to create your management group hierarchy
- [Managing Management Group Hierarchy](Management-Group-Hierarchy/Managing-Management-Group-Hierarchy.md) - Best practices for ongoing management and updates

## Quick Links

- **Bicep Template**: `code/bicep/mg-hierarchy/mg-hierarchy.bicep`
- **Parameters File**: `code/bicep/mg-hierarchy/mg-hierarchy.bicepparam`
- **Pipeline**: `code/pipelines/01-mg-hierarchy-pipeline.yaml`

## Key Concepts

- **Tenant Root Management Group**: The top-level management group in your Azure AD tenant
- **Organization Root**: Your organization's root management group (created below tenant root)
- **Platform Management Groups**: Management groups for platform services (connectivity, management)
- **Landing Zone Management Groups**: Management groups for application workloads
- **Sandbox**: Management group for experimentation and testing
- **Decommissioned**: Management group for resources being retired
