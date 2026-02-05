# Role Assignments

This section provides comprehensive documentation for deploying and managing Role-Based Access Control (RBAC) assignments across your Azure environment.

## Overview

The Role Assignments infrastructure deploys RBAC assignments at the management group level. This ensures that users and groups have the appropriate permissions across the entire management group hierarchy, enabling a secure and manageable access control model.

## Documentation Structure

- [Role Assignments Overview](Role-Assignments/Role-Assignments-Overview.md) - Learn about the architecture and RBAC strategy
- [Deploying Role Assignments](Role-Assignments/Deploying-Role-Assignments.md) - Step-by-step deployment guide
- [Managing Role Assignments](Role-Assignments/Managing-Role-Assignments.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/role-assignments/role-assignments.bicep`
- **Parameters File**: `code/bicep/role-assignments/role-assignments.bicepparam`
- **Pipeline**: `code/pipelines/role-assignments/role-assignments-pipeline.yaml`

## Key Concepts

- **RBAC**: Role-Based Access Control, restricting access based on the role of the user
- **Principal**: The user, group, or service principal receiving the access
- **Role Definition**: The collection of permissions (e.g., Owner, Contributor, Reader)
- **Scope**: The resources that the access applies to (Management Group, Subscription, Resource Group)
- **Inheritance**: Permissions assigned at a higher level (Management Group) trigger down to all child resources
