targetScope = 'managementGroup'

// ============================================================================
// ROLE ASSIGNMENTS
// ============================================================================
// Module to manage RBAC assignments at the Management Group scope.
// ============================================================================

// ============================================================================
// PAREMETERS
// ============================================================================

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The owner of the infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

@description('Array of role assignments to deploy.')
param roleAssignments array = []

// ============================================================================
// RESOURCES
// ============================================================================

// We iteration over the array to create assignments
// Note: We use a module for the actual assignment to handle the loop cleanly if needed,
// strictly speaking we can do resource iteration directly.
// Given strict consistency requirements, let's use the resource iteration directly for simplicity unless complexity demands a submodule.
// ALZ uses a module for this, but for this simplified repo, direct resource is cleaner.

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (assignment, i) in roleAssignments: {
    name: guid(managementGroup().id, assignment.principalId, assignment.roleDefinitionId)
    properties: {
      roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
      principalId: assignment.principalId
      principalType: contains(assignment, 'principalType') ? assignment.principalType : 'ServicePrincipal'
      description: contains(assignment, 'description') ? assignment.description : ''
    }
  }
]

// ============================================================================
// OUTPUTS
// ============================================================================

// No direct outputs needed typically for RBAC, but we can output count
output roleAssignmentCount int = length(roleAssignments)
