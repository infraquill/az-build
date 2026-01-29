targetScope = 'subscription'

// ============================================================================
// SPOKE NETWORKING INFRASTRUCTURE
// Deploys spoke networking infrastructure including:
// - Resource Group
// - Spoke Virtual Network with workload subnets
// - Private DNS Zone link to hub
// - Optional: IPAM static CIDR allocation
// All diagnostic settings send logs/metrics to the common Log Analytics Workspace
// AVNM automatically connects spokes to hub when in the connectivity management group scope
// ============================================================================

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The workload alias used in naming conventions (e.g., webapp, cloudops, mngmnt)')
param workloadAlias string

@description('The environment (e.g., dev, test, prod)')
param environment string

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string = '001'

@description('The Azure region for the spoke resources')
param location string = 'canadacentral'

@description('The address space for the spoke virtual network (e.g., 10.1.0.0/16)')
param spokeVnetAddressSpace string

@description('Resource ID of the Log Analytics Workspace from monitoring infrastructure')
param logAnalyticsWorkspaceResourceId string

@description('The owner of the spoke infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// Hub infrastructure references
@description('The name of the hub Private DNS Zone (e.g., internal.organization.com)')
param hubPrivateDnsZoneName string

@description('The resource ID of the hub Private DNS Zone')
param hubPrivateDnsZoneResourceId string

@description('The resource group name where the hub Private DNS Zone is located')
param hubResourceGroupName string

@description('The subscription ID where the hub infrastructure is located')
param hubSubscriptionId string

// IPAM configuration (optional)
@description('Enable IPAM static CIDR allocation for this spoke VNet')
param enableIpamAllocation bool = false

@description('The name of the hub AVNM (required if enableIpamAllocation is true)')
param hubAvnmName string = ''

@description('The name of the hub IPAM Pool (required if enableIpamAllocation is true)')
param hubIpamPoolName string = ''

// Subnet configuration
@description('Custom subnet definitions. If empty, a default workload subnet will be created.')
param customSubnets array = []

// ============================================================================
// VARIABLES
// ============================================================================

// Naming convention variables
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var spokeVnetName = 'vnet-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Common tags
var commonTags = {
  Project: workloadAlias
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// Default subnet configuration if no custom subnets are provided
var defaultSubnets = [
  {
    name: 'workload'
    addressPrefix: cidrSubnet(spokeVnetAddressSpace, 24, 0) // First /24 subnet
  }
]

// Use custom subnets if provided, otherwise use default
var subnetsToCreate = !empty(customSubnets) ? customSubnets : defaultSubnets

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// SPOKE VIRTUAL NETWORK
// ============================================================================

module spokeVnet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${spokeVnetName}'
  scope: spokeResourceGroup
  params: {
    name: spokeVnetName
    location: location
    addressPrefixes: [
      spokeVnetAddressSpace
    ]
    subnets: subnetsToCreate
    diagnosticSettings: [
      {
        name: 'vnet-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// IPAM STATIC CIDR ALLOCATION (Optional)
// Allocates the spoke VNet address space in the hub IPAM Pool
// ============================================================================

module spokeIpamAllocation './ipam-static-cidr.bicep' = if (enableIpamAllocation) {
  name: 'deploy-ipam-staticcidr-${spokeVnetName}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    networkManagerName: hubAvnmName
    ipamPoolName: hubIpamPoolName
    staticCidrName: '${spokeVnetName}-allocation'
    addressPrefixes: [
      spokeVnetAddressSpace
    ]
    cidrDescription: 'Spoke VNet ${spokeVnetName} address space allocation'
  }
  dependsOn: [
    spokeVnet
  ]
}

// ============================================================================
// PRIVATE DNS ZONE LINK
// Links the spoke VNet to the hub's Private DNS Zone for DNS resolution
// ============================================================================

module privateDnsZoneLink 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'deploy-privateDnsZone-${spokeVnetName}-link'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    name: hubPrivateDnsZoneName
    virtualNetworkLinks: [
      {
        name: '${spokeVnetName}-link'
        virtualNetworkResourceId: spokeVnet.outputs.resourceId
        registrationEnabled: true
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output resourceGroupName string = spokeResourceGroup.name

@description('The resource ID of the resource group')
output resourceGroupId string = spokeResourceGroup.id

@description('The name of the Spoke Virtual Network')
output spokeVnetName string = spokeVnet.outputs.name

@description('The resource ID of the Spoke Virtual Network')
output spokeVnetResourceId string = spokeVnet.outputs.resourceId

@description('The subnet resource IDs of the Spoke Virtual Network')
output spokeVnetSubnetResourceIds array = spokeVnet.outputs.subnetResourceIds

@description('The subnet names of the Spoke Virtual Network')
output spokeVnetSubnetNames array = spokeVnet.outputs.subnetNames

@description('The address space of the Spoke Virtual Network')
output spokeVnetAddressSpace string = spokeVnetAddressSpace

@description('The resource ID of the IPAM allocation (if enabled)')
output ipamAllocationResourceId string = enableIpamAllocation ? spokeIpamAllocation.outputs.resourceId : ''

@description('Private DNS Zone link status')
output privateDnsZoneLinkName string = '${spokeVnetName}-link'
