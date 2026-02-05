using 'role-assignments.bicep'

// ============================================================================
// ROLE ASSIGNMENTS PARAMETERS
// ============================================================================

param environment = 'live'

param owner = 'platform-team@arcnovus.net'

param managedBy = 'Bicep'

// Example structure - actual values should come from variable groups or be empty by default
param roleAssignments = [
  /* 
  {
    principalId: '<principal-id>'
    roleDefinitionId: '<role-definition-id>' // e.g., '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' (Owner)
    description: 'Owner assignment for Platform Team'
    principalType: 'Group'
  }
  */
]
