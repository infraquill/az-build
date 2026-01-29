// ============================================================================
// SUBSCRIPTION VENDING - DIRECT RESOURCE IMPLEMENTATION
// ============================================================================
//
// AVM MODULE ABANDONMENT
// ----------------------
// This template previously used the Azure Verified Module (AVM) sub-vending
// pattern module (br/public:avm/ptn/lz/sub-vending). However, we encountered
// a critical bug in version 0.5.2 (and potentially earlier versions) where
// the module internally references an invalid API version '2025-04-01' for
// Microsoft.Management/managementGroups, which does not exist in Azure.
//
// Error Encountered:
//   InvalidResourceType: The resource type 'managementGroups' could not be
//   found in the namespace 'Microsoft.Management' for api version '2025-04-01'.
//   The supported api-versions are: '2024-02-01-preview, 2023-04-01, ...'
//
// Rationale for Direct Implementation:
//   1. Full control over API versions and resource definitions
//   2. No dependency on external module bugs or version compatibility
//   3. Simplified deployment model (tenant scope vs nested module complexity)
//   4. Direct access to all subscription properties and features
//   5. Better alignment with organizational requirements
//
// Current Implementation:
//   - Deployment Scope: Tenant (required for subscription alias creation)
//   - Subscription Creation: Microsoft.Subscription/aliases@2024-08-01-preview
//   - Management Group Association: Microsoft.Management/managementGroups/subscriptions@2024-02-01-preview
//   - Management Group Reference: Microsoft.Management/managementGroups@2023-04-01
//
// Features:
//   - Creates new subscriptions with proper naming convention
//   - Assigns subscriptions to target management group
//   - Applies standardized tags for governance
//   - Supports moving existing subscriptions to management groups
//
// ============================================================================

targetScope = 'tenant'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The project name used for tagging.')
param projectName string

@description('The management group ID (name) where the subscription will be placed (e.g. "corp-platform").')
param managementGroupId string

@description('The billing scope for the subscription. Required for EA/MCA/MPA subscription creation. Optional for other scenarios. See Microsoft docs for formats.')
param billingScope string = ''

@description('The workload type for the subscription. Valid values: Production, DevTest')
@allowed([
  'Production'
  'DevTest'
])
param workload string = 'Production'

@description('The workload alias used in naming conventions (e.g., hub, mngmnt, cloudops).')
param workloadAlias string

@description('The environment for the subscription (e.g., dev, test, prod).')
param environment string

@description('The location code for the subscription (e.g., cac).')
param locationCode string = 'cac'

@description('The instance number for the subscription (e.g., 001).')
param instanceNumber string

@description('The owner tag value.')
param owner string

@description('ManagedBy tag value.')
param managedBy string = 'Bicep'

@description('Optional: The ID of an existing subscription to move. If provided, skips subscription creation.')
param existingSubscriptionId string = ''

// ============================================================================
// VARIABLES
// ============================================================================

// Convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
var subscriptionAliasName = 'subcr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Management group resource ID string used by alias + move
var targetMgResourceId = '/providers/Microsoft.Management/managementGroups/${managementGroupId}'

// ============================================================================
// RESOURCES
// ============================================================================

// Reference the target management group
resource targetMg 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: managementGroupId
}

// Only create a new subscription if no existing subscription ID is provided
resource subscriptionAlias 'Microsoft.Subscription/aliases@2024-08-01-preview' = if (empty(existingSubscriptionId)) {
  name: subscriptionAliasName
  properties: {
    displayName: subscriptionAliasName
    workload: workload
    // Only set billingScope if provided (some scenarios may not require it)
    billingScope: empty(billingScope) ? null : billingScope
    additionalProperties: {
      managementGroupId: targetMgResourceId
      tags: {
        Project: projectName
        Environment: environment
        Owner: owner
        ManagedBy: managedBy
      }
    }
  }
}

// Move existing subscription to the target management group
resource mgSubscriptionAssociationExisting 'Microsoft.Management/managementGroups/subscriptions@2024-02-01-preview' = if (!empty(existingSubscriptionId)) {
  parent: targetMg
  name: existingSubscriptionId
}

// ============================================================================
// OUTPUTS
// ============================================================================

// output subscriptionAliasName string = subscriptionAliasName
// output subscriptionId string = !empty(existingSubscriptionId)
//   ? existingSubscriptionId
//   : subscriptionAlias.properties.subscriptionId
// output managementGroupResourceId string = targetMgResourceId
// output isExistingSubscription bool = !empty(existingSubscriptionId)
