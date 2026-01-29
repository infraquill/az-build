# Subscription Vending Overview

## Introduction

Subscription vending provides an automated, standardized way to create Azure subscriptions with consistent naming conventions, proper management group placement, and governance tags. This process ensures all subscriptions follow organizational standards and are properly organized within your management group hierarchy.

## Architecture

```
Tenant Scope Deployment
└── Subscription Alias (subcr-<workloadAlias>-<env>-<loc>-<instance>)
    └── Azure Subscription
        ├── Display Name (same as alias)
        ├── Management Group Assignment
        ├── Billing Scope (optional)
        ├── Workload Type (Production/DevTest)
        └── Tags:
            ├── Project: <workloadAlias>
            ├── Environment: <environment>
            ├── Owner: <owner>
            └── ManagedBy: <managedBy>
```

## Core Components

### Subscription Alias

The subscription alias is a unique identifier that follows a consistent naming convention:

- **Pattern**: `subcr-<workloadAlias>-<environment>-<locationCode>-<instanceNumber>`
- **Example**: `subcr-hub-live-cac-001`

**Components:**
- **subcr**: Prefix indicating subscription creation
- **workloadAlias**: The workload alias used in naming conventions (e.g., `hub`, `spoke`, `mngmnt`)
- **environment**: Environment identifier (e.g., `dev`, `test`, `prod`, `live`)
- **locationCode**: Short location code (e.g., `cac` for Canada Central)
- **instanceNumber**: Instance identifier (e.g., `001`, `002`)

### Subscription Display Name

The human-readable name for the subscription in the Azure Portal. This can be different from the alias and is more descriptive.

**Example**: `Hub Infrastructure - Production - Canada Central`

### Management Group Assignment

Subscriptions are automatically assigned to the specified management group upon creation. This ensures proper governance, policy application, and organizational structure.

**Supported Management Groups:**
- Root tenant management group
- `mg-platform`
- `mg-landing-zone`
- `mg-sandbox`
- `mg-decommissioned`
- `mg-management`
- `mg-connectivity`
- `mg-corp-prod`
- `mg-corp-non-prod`
- `mg-online-prod`
- `mg-online-non-prod`
- Custom management groups

### Billing Scope

Optional billing account configuration for Enterprise Agreement (EA) and Microsoft Customer Agreement (MCA) scenarios.

**Format**: `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}`

**When Required:**
- Enterprise Agreement subscriptions
- Microsoft Customer Agreement subscriptions
- When billing needs to be assigned to a specific invoice section

**When Optional:**
- Pay-as-you-go subscriptions
- When billing is handled at the tenant level

### Workload Type

Classifies the subscription based on its intended use:

| Type | Description | Use Cases |
|------|-------------|-----------|
| `Production` | Production workloads | Live services, customer-facing applications |
| `DevTest` | Development and testing | Development environments, testing, non-production workloads |

**Note**: DevTest subscriptions may have different pricing and feature availability.

### Standardized Tags

All subscriptions are automatically tagged with consistent metadata:

| Tag | Description | Example |
|-----|-------------|---------|
| `Project` | Workload alias | `hub`, `monitoring`, `spoke` |
| `Environment` | Environment identifier | `dev`, `test`, `prod`, `live` |
| `Owner` | Subscription owner | Email address or team name |
| `ManagedBy` | Management tool | `Bicep`, `Terraform`, `ARM` |

These tags enable:
- Cost allocation and chargeback
- Policy-based governance
- Resource organization and filtering
- Automated management and reporting

## Naming Convention

The subscription alias follows a strict naming convention to ensure consistency and enable automation:

```
subcr-<workloadAlias>-<environment>-<locationCode>-<instanceNumber>
```

### Naming Components

| Component | Description | Examples |
|-----------|-------------|----------|
| `workloadAlias` | Workload alias for naming conventions | `hub`, `spoke`, `mngmnt`, `cloudops` |
| `environment` | Environment name | `dev`, `test`, `uat`, `staging`, `prod`, `live`, `nonprod` |
| `locationCode` | Short location code | `cac` (Canada Central), `cae` (Canada East), `eus` (East US) |
| `instanceNumber` | Three-digit instance identifier | `001`, `002`, `003` |

### Examples

| Workload Alias | Environment | Location | Instance | Alias |
|----------------|-------------|----------|----------|-------|
| hub | Live | Canada Central | 001 | `subcr-hub-live-cac-001` |
| monitoring | Prod | Canada Central | 001 | `subcr-monitoring-prod-cac-001` |
| spoke | Dev | Canada Central | 001 | `subcr-spoke-dev-cac-001` |
| governance | Nonprod | Canada Central | 001 | `subcr-governance-nonprod-cac-001` |

## Implementation Approach

This implementation uses direct Bicep resource definitions rather than the Azure Verified Module (AVM) sub-vending pattern.

### Why Not AVM?

The Azure Verified Module `br/public:avm/ptn/lz/sub-vending` was initially used but abandoned due to a critical bug where the module internally references an invalid API version (`2025-04-01`) for `Microsoft.Management/managementGroups`. This caused deployment failures with `InvalidResourceType` errors.

### Current Implementation

The direct implementation provides:

- **Subscription Creation**: Uses `Microsoft.Subscription/aliases@2024-08-01-preview`
- **Management Group Association**: Uses `Microsoft.Management/managementGroups/subscriptions@2024-02-01-preview`
- **Management Group Reference**: Uses `Microsoft.Management/managementGroups@2023-04-01`
- **Full Control**: Direct control over API versions and resource definitions
- **No External Dependencies**: No dependency on external module bugs or version compatibility
- **Simplified Model**: Tenant scope deployment without nested module complexity
- **Existing Subscription Support**: Can move existing subscriptions to management groups

## Integration Points

### Management Group Hierarchy

Subscription vending integrates with the management group hierarchy:

- **Placement**: Subscriptions are automatically placed in the correct management group
- **Governance**: Policies applied at the management group level affect new subscriptions
- **Organization**: Maintains organizational structure and hierarchy

### Billing and Cost Management

- **Billing Scope**: Optional billing account assignment for cost tracking
- **Tags**: Standardized tags enable cost allocation and chargeback
- **Workload Type**: DevTest subscriptions may have different pricing

### Governance and Compliance

- **Policy Inheritance**: Subscriptions inherit policies from their management group
- **Tagging**: Consistent tags enable policy-based governance
- **Audit Trail**: All subscriptions are tracked with owner and management tool information

## Default Configuration

The default deployment configuration:

| Parameter | Default Value |
|-----------|---------------|
| Workload | `Production` |
| Location Code | `cac` |
| Managed By | `Bicep` |
| Billing Scope | Empty (optional) |

**Required Parameters:**
- `managementGroupId`
- `workloadAlias`
- `environment`
- `instanceNumber`
- `owner`

**Optional Parameters:**
- `existingSubscriptionId` - If provided, moves an existing subscription instead of creating a new one

## Deployment Scope

Subscription vending is deployed at the **tenant scope**, which allows:

- Creating subscriptions using subscription aliases (requires tenant scope)
- Assigning subscriptions to any management group
- Centralized subscription management
- Consistent deployment process
- Moving existing subscriptions between management groups

## Outputs

The deployment provides these outputs:

| Output | Description |
|--------|-------------|
| `subscriptionAliasName` | The subscription alias name following the naming convention |
| `subscriptionId` | The subscription ID (GUID) |
| `managementGroupResourceId` | The full resource ID of the target management group |
| `isExistingSubscription` | Boolean indicating if an existing subscription was moved |

These outputs can be used for:
- Subsequent deployments that reference the subscription
- Automation and scripting
- Documentation and tracking
- Integration with other systems

## Use Cases

### 1. Hub Infrastructure Subscription

Create a subscription for hub networking infrastructure:

- **Workload Alias**: `hub`
- **Environment**: `live`
- **Management Group**: `mg-connectivity`
- **Workload**: `Production`

### 2. Development Environment Subscription

Create a subscription for development workloads:

- **Workload Alias**: `app-dev`
- **Environment**: `dev`
- **Management Group**: `mg-online-non-prod`
- **Workload**: `DevTest`

### 3. Monitoring Subscription

Create a subscription for monitoring infrastructure:

- **Workload Alias**: `monitoring`
- **Environment**: `prod`
- **Management Group**: `mg-management`
- **Workload**: `Production`

### 4. Sandbox Subscription

Create a subscription for testing and experimentation:

- **Workload Alias**: `sandbox`
- **Environment**: `dev`
- **Management Group**: `mg-sandbox`
- **Workload**: `DevTest`

## Best Practices

### 1. Naming Convention

- **Follow the Pattern**: Always use the `subcr-<workloadAlias>-<env>-<loc>-<instance>` pattern
- **Be Descriptive**: Use clear, meaningful workload alias and environment names
- **Consistency**: Maintain consistent naming across all subscriptions

### 2. Management Group Placement

- **Organizational Structure**: Place subscriptions in management groups that reflect organizational structure
- **Governance Alignment**: Align management group placement with governance requirements
- **Policy Inheritance**: Consider policy inheritance when selecting management groups

### 3. Tagging

- **Complete Information**: Always provide owner and workload alias information
- **Consistent Values**: Use consistent tag values across subscriptions
- **Review Regularly**: Periodically review and update tags

### 4. Billing Scope

- **EA/MCA Scenarios**: Always specify billing scope for Enterprise Agreement and MCA scenarios
- **Cost Tracking**: Use billing scope for accurate cost allocation
- **Documentation**: Document billing scope assignments

### 5. Workload Type

- **Correct Classification**: Use DevTest for development and testing workloads
- **Cost Optimization**: Leverage DevTest pricing for non-production workloads
- **Compliance**: Ensure workload type aligns with compliance requirements

## Limitations and Considerations

### Subscription Limits

- **Per Tenant**: Azure has limits on the number of subscriptions per tenant
- **Per Account**: Billing account may have subscription limits
- **Quota**: Some Azure services have subscription-level quotas

### Permissions

- **Tenant Scope**: Requires appropriate permissions at tenant scope for subscription alias creation
- **Management Group Scope**: Requires permissions at management group scope for subscription assignment
- **Billing**: Billing scope configuration may require billing account permissions
- **Subscription Creation**: Requires subscription creation permissions (Owner at Tenant Root MG)

### Billing

- **EA/MCA**: Billing scope is required for EA and MCA scenarios
- **Pay-as-you-go**: Billing scope is optional for pay-as-you-go subscriptions
- **Cost Allocation**: Tags enable cost allocation but billing scope provides more granular control

## Next Steps

- [Deploying Subscription Vending](Deploying-Subscription-Vending.md) - Learn how to deploy
- [Managing Subscription Vending](Managing-Subscription-Vending.md) - Ongoing management
