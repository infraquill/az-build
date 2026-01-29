targetScope = 'managementGroup'

@description('The location for the policy assignment resources (required for managed identity)')
param location string = 'canadacentral'

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The owner of the governance infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

@description('Enable Microsoft Cloud Security Benchmark policy assignment')
param enableMCSB bool = true

@description('Enable Canada Federal PBMM policy assignment')
param enableCanadaPBMM bool = true

@description('The enforcement mode for the policy assignment. ("DoNotEnforce", "Default")')
@allowed([
  'DoNotEnforce'
  'Default'
])
param enforcementMode string = 'DoNotEnforce'

// Built-in Policy Initiative IDs
var mcsbInitiativeId = '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
var canadaPbmmInitiativeId = '/providers/Microsoft.Authorization/policySetDefinitions/4c4a5f27-de81-430b-b4e5-9cbd50595a87'

// Microsoft Cloud Security Benchmark Policy Assignment
resource mcsbAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enableMCSB) {
  name: 'mcsb-audit-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Microsoft Cloud Security Benchmark - Audit'
    description: 'Microsoft Cloud Security Benchmark assigned in audit mode. Diagnostic settings are managed separately by infrastructure pipelines.'
    policyDefinitionId: mcsbInitiativeId
    enforcementMode: 'DoNotEnforce'
    metadata: {
      assignedBy: managedBy
      environment: environment
      owner: owner
    }
    nonComplianceMessages: [
      {
        message: 'This resource is not compliant with the Microsoft Cloud Security Benchmark. Review the policy details for remediation guidance.'
      }
    ]
  }
}

// Canada Federal PBMM Policy Assignment
resource canadaPbmmAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enableCanadaPBMM) {
  name: 'canada-pbmm-audit-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Canada Federal PBMM - Audit'
    description: 'Canada Federal Protected B / Medium Integrity / Medium Availability (PBMM) compliance policy assigned in audit mode. Diagnostic settings are managed separately by infrastructure pipelines.'
    policyDefinitionId: canadaPbmmInitiativeId
    enforcementMode: 'DoNotEnforce'
    metadata: {
      assignedBy: managedBy
      environment: environment
      owner: owner
    }
    nonComplianceMessages: [
      {
        message: 'This resource is not compliant with Canada Federal PBMM requirements. Review the policy details for remediation guidance.'
      }
    ]
  }
}

// Outputs
@description('MCSB Policy Assignment Resource ID')
output mcsbAssignmentId string = enableMCSB ? mcsbAssignment.id : ''

@description('MCSB Policy Assignment Name')
output mcsbAssignmentName string = enableMCSB ? mcsbAssignment.name : ''

@description('MCSB Policy Assignment Managed Identity Principal ID')
// Note: BCP318 warning is a false positive - the ternary operator ensures the resource exists before access
output mcsbPrincipalId string = enableMCSB ? mcsbAssignment.identity.principalId : ''

@description('Canada PBMM Policy Assignment Resource ID')
output canadaPbmmAssignmentId string = enableCanadaPBMM ? canadaPbmmAssignment.id : ''

@description('Canada PBMM Policy Assignment Name')
output canadaPbmmAssignmentName string = enableCanadaPBMM ? canadaPbmmAssignment.name : ''

@description('Canada PBMM Policy Assignment Managed Identity Principal ID')
// Note: BCP318 warning is a false positive - the ternary operator ensures the resource exists before access
output canadaPbmmPrincipalId string = enableCanadaPBMM ? canadaPbmmAssignment.identity.principalId : ''
