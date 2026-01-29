targetScope = 'subscription'

// ============================================================================
// DEVCENTER INFRASTRUCTURE
// Deploys DevCenter infrastructure required for Managed DevOps Pools:
// - Resource Group for DevCenter resources
// - DevCenter (organizational container for projects and pools)
// - Network Connection (enables private networking for Managed DevOps Pools)
// Prerequisites:
// - CloudOps subscription must exist (Stage 1: sub-vending)
// - CloudOps spoke networking must be deployed (Stage 2: spoke-networking)
// - Monitoring infrastructure must be deployed (for Log Analytics)
// Note: DevCenter is typically deployed once and shared across multiple pools
// ============================================================================

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The workload alias used in naming conventions (e.g., devcenter, hub, mngmnt)')
param workloadAlias string = 'devcenter'

@description('The environment (e.g., dev, test, prod, live)')
param environment string = 'live'

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string = '001'

@description('The Azure region for the DevCenter resources')
param location string = 'canadacentral'

@description('The owner of the DevCenter infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// Spoke networking references
@description('The resource ID of the subnet for Network Connection')
param subnetResourceId string

// Monitoring
@description('Resource ID of the Log Analytics Workspace from monitoring infrastructure')
param logAnalyticsWorkspaceResourceId string

// ============================================================================
// VARIABLES
// ============================================================================

// Naming convention variables
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var devCenterName = 'dc-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var networkConnectionName = 'nc-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Common tags
var commonTags = {
  Project: workloadAlias
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource devCenterResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// DEVCENTER
// ============================================================================

module devCenter 'br/public:avm/res/dev-center/devcenter:0.1.0' = {
  name: 'deploy-${devCenterName}'
  scope: devCenterResourceGroup
  params: {
    name: devCenterName
    location: location
    tags: commonTags
  }
}

// ============================================================================
// NETWORK CONNECTION
// Enables private networking for Managed DevOps Pools
// ============================================================================

module networkConnection 'br/public:avm/res/dev-center/network-connection:0.1.0' = {
  name: 'deploy-${networkConnectionName}'
  scope: devCenterResourceGroup
  params: {
    name: networkConnectionName
    location: location
    subnetResourceId: subnetResourceId
    domainJoinType: 'None' // Azure AD join - no on-premises domain
    tags: commonTags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output resourceGroupName string = devCenterResourceGroup.name

@description('The resource ID of the resource group')
output resourceGroupId string = devCenterResourceGroup.id

@description('The name of the DevCenter')
output devCenterName string = devCenter.outputs.name

@description('The resource ID of the DevCenter')
output devCenterResourceId string = devCenter.outputs.resourceId

@description('The name of the Network Connection')
output networkConnectionName string = networkConnection.outputs.name

@description('The resource ID of the Network Connection')
output networkConnectionResourceId string = networkConnection.outputs.resourceId
