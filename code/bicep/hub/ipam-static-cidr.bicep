// ============================================================================
// IPAM STATIC CIDR MODULE
// Deploys Static CIDR allocation as a child resource of IPAM Pool
// This module must be deployed at resource group scope
// ============================================================================

targetScope = 'resourceGroup'

@description('The name of the existing Network Manager')
param networkManagerName string

@description('The name of the existing IPAM Pool')
param ipamPoolName string

@description('The name of the Static CIDR allocation')
param staticCidrName string

@description('The address prefixes for the Static CIDR allocation')
param addressPrefixes array

@description('Description for the Static CIDR allocation')
param cidrDescription string = ''

// Reference the existing IPAM Pool
resource ipamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' existing = {
  name: '${networkManagerName}/${ipamPoolName}'
}

// Create the Static CIDR as a child resource of the IPAM Pool
resource staticCidr 'Microsoft.Network/networkManagers/ipamPools/staticCidrs@2024-05-01' = {
  parent: ipamPool
  name: staticCidrName
  properties: {
    addressPrefixes: addressPrefixes
    description: cidrDescription
  }
}

@description('The resource ID of the Static CIDR')
output resourceId string = staticCidr.id

@description('The name of the Static CIDR')
output name string = staticCidr.name
