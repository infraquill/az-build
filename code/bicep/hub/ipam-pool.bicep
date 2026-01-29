// ============================================================================
// IPAM POOL MODULE
// Deploys IPAM Pool as a child resource of Azure Virtual Network Manager
// This module must be deployed at resource group scope
// ============================================================================

targetScope = 'resourceGroup'

@description('The name of the existing Network Manager')
param networkManagerName string

@description('The name of the IPAM Pool')
param ipamPoolName string

@description('The Azure region for the IPAM Pool')
param location string

@description('The address prefixes for the IPAM Pool')
param addressPrefixes array

@description('Description for the IPAM Pool')
param poolDescription string = ''

@description('Tags to apply to the IPAM Pool')
param tags object = {}

// Reference the existing Network Manager
resource networkManager 'Microsoft.Network/networkManagers@2024-05-01' existing = {
  name: networkManagerName
}

// Create the IPAM Pool as a child resource
resource ipamPool 'Microsoft.Network/networkManagers/ipamPools@2024-05-01' = {
  parent: networkManager
  name: ipamPoolName
  location: location
  properties: {
    addressPrefixes: addressPrefixes
    description: poolDescription
  }
  tags: tags
}

@description('The resource ID of the IPAM Pool')
output resourceId string = ipamPool.id

@description('The name of the IPAM Pool')
output name string = ipamPool.name
