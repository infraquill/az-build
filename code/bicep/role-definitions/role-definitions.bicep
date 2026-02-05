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
// CUSTOM ROLE DEFINITIONS
// ============================================================================

// Example: NetOps Role
// Grants permissions to manage network resources, but not create/delete VNets or Peerings (example constraint)
resource netOpsRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('netops-role', managementGroup().id)
  properties: {
    roleName: 'NetOps-${environment}'
    description: 'Custom role for Network Operations team'
    type: 'Custom'
    assignableScopes: [
      managementGroup().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Network/*/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
          'Microsoft.Network/loadBalancers/*'
          'Microsoft.Network/networkSecurityGroups/*'
          'Microsoft.Network/publicIPAddresses/*'
          'Microsoft.Network/networkInterfaces/*'
        ]
        notActions: [
          'Microsoft.Network/virtualNetworks/write'
          'Microsoft.Network/virtualNetworks/delete'
          'Microsoft.Network/virtualNetworkPeerings/write'
          'Microsoft.Network/virtualNetworkPeerings/delete'
        ]
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The ID of the NetOps role definition')
output netOpsRoleDefinitionId string = netOpsRoleDefinition.id
