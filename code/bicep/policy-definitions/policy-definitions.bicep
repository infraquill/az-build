targetScope = 'managementGroup'

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The owner of the infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// ============================================================================
// CUSTOM POLICY DEFINITIONS
// ============================================================================

// Example: Deny Public IP creation
// This is a common ALZ sample policy
resource denyPublicIpDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'deny-public-ip'
  properties: {
    displayName: 'Deny Public IP Creation'
    policyType: 'Custom'
    mode: 'Indexed'
    description: 'This policy denies creation of Public IPs to ensure all traffic goes through approved gateways.'
    metadata: {
      category: 'Network'
      assignedBy: managedBy
      owner: owner
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit' // Non-blocking by default for safety
      }
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Network/publicIPAddresses'
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The ID of the Deny Public IP policy definition')
output denyPublicIpDefinitionId string = denyPublicIpDefinition.id
