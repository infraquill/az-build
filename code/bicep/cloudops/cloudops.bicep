targetScope = 'subscription'

// ============================================================================
// CLOUDOPS WORKLOAD INFRASTRUCTURE - MANAGED DEVOPS POOLS
// Deploys CloudOps workload infrastructure using Azure Managed DevOps Pools:
// - Resource Group for CloudOps workload resources
// - DevCenter Project (organizational container for pools)
// - Managed DevOps Pool (Azure-managed agents with native scale-to-zero)
// Prerequisites:
// - CloudOps subscription must exist (Stage 1: sub-vending)
// - CloudOps spoke networking must be deployed (Stage 2: spoke-networking)
// - DevCenter infrastructure must be deployed (Stage 3: devcenter)
// - Hub infrastructure must be deployed (for AVNM connectivity)
// - Monitoring infrastructure must be deployed (for Log Analytics)
// Benefits of Managed DevOps Pools:
// - Automatic agent management - no custom scripts or PAT tokens needed
// - Native scale-to-zero - built-in support via Stateless agent profile
// - Automatic updates - agent software maintained by Azure
// - Well-known images - pre-configured Azure DevOps images
// - Simplified configuration - no VMSS extensions or cloud-init scripts
// ============================================================================

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The workload alias used in naming conventions (e.g., cloudops, hub, mngmnt)')
param workloadAlias string = 'cloudops'

@description('The environment (e.g., dev, test, prod, live)')
param environment string = 'live'

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string = '001'

@description('The Azure region for the CloudOps resources')
param location string = 'canadacentral'

@description('The owner of the CloudOps infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// DevCenter references (from Stage 3: devcenter deployment)
@description('The resource ID of the DevCenter')
param devCenterResourceId string

// Spoke networking references (from Stage 2 deployment)
@description('The resource ID of the subnet where pool agents will be deployed')
param poolSubnetResourceId string

// Managed DevOps Pool Configuration
@description('The maximum number of agents in the pool (concurrency). Minimum is 1.')
@minValue(1)
@maxValue(10000)
param poolMaximumConcurrency int = 4

@description('The VM SKU size for the pool agents')
param poolAgentSkuName string = 'Standard_D2s_v5'

@description('Azure DevOps organization URL (e.g., https://dev.azure.com/myorg)')
param azureDevOpsOrganizationUrl string

@description('Optional: Specific Azure DevOps project names to scope the pool to. Leave empty for organization-wide.')
param azureDevOpsProjectNames array = []

@description('Enable scale-to-zero when no jobs are queued (MostCostEffective prediction preference)')
param enableScaleToZero bool = true

@description('The image to use for pool agents. Use well-known images for pre-configured environments.')
@allowed([
  'ubuntu-22.04/latest'
  'ubuntu-24.04/latest'
  'windows-2022/latest'
  'windows-2019/latest'
])
param poolImageName string = 'ubuntu-22.04/latest'

// ============================================================================
// VARIABLES
// ============================================================================

// Naming convention variables
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var devCenterProjectName = 'dcp-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var managedPoolName = 'mdp-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Common tags
var commonTags = {
  Project: workloadAlias
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// Build organization profile with optional project scoping
var organizationProfile = {
  kind: 'AzureDevOps'
  organizations: [
    {
      url: azureDevOpsOrganizationUrl
      projects: empty(azureDevOpsProjectNames) ? null : azureDevOpsProjectNames
      parallelism: poolMaximumConcurrency
    }
  ]
  permissionProfile: {
    kind: 'CreatorOnly'
  }
}

// Agent profile configuration for scale-to-zero support
var agentProfile = {
  kind: 'Stateless'
  resourcePredictionsProfile: enableScaleToZero
    ? {
        kind: 'Automatic'
        predictionPreference: 'MostCostEffective'
      }
    : {
        kind: 'Automatic'
        predictionPreference: 'Balanced'
      }
}

// Image configuration for the pool
var poolImages = [
  {
    wellKnownImageName: poolImageName
  }
]

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource cloudopsResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// DEVCENTER PROJECT
// Organizational container for Managed DevOps Pools
// Links to the DevCenter and enables pool management
// ============================================================================

module devCenterProject 'br/public:avm/res/dev-center/project:0.1.0' = {
  name: 'deploy-${devCenterProjectName}'
  scope: cloudopsResourceGroup
  params: {
    name: devCenterProjectName
    devCenterResourceId: devCenterResourceId
    location: location
    tags: commonTags
  }
}

// ============================================================================
// MANAGED DEVOPS POOL
// Azure-managed agents with native scale-to-zero support
// Uses Azure Verified Module for Managed DevOps Pool
// ============================================================================

module managedDevOpsPool 'br/public:avm/res/dev-ops-infrastructure/pool:0.7.0' = {
  name: 'deploy-${managedPoolName}'
  scope: cloudopsResourceGroup
  params: {
    name: managedPoolName
    location: location
    devCenterProjectResourceId: devCenterProject.outputs.resourceId
    agentProfile: agentProfile
    organizationProfile: organizationProfile
    fabricProfileSkuName: poolAgentSkuName
    images: poolImages
    subnetResourceId: poolSubnetResourceId
    concurrency: poolMaximumConcurrency
    tags: union(commonTags, {
      Purpose: 'DevOps-Agent'
      PoolType: 'ManagedDevOpsPool'
    })
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output resourceGroupName string = cloudopsResourceGroup.name

@description('The resource ID of the resource group')
output resourceGroupId string = cloudopsResourceGroup.id

@description('The name of the DevCenter Project')
output devCenterProjectName string = devCenterProject.outputs.name

@description('The resource ID of the DevCenter Project')
output devCenterProjectResourceId string = devCenterProject.outputs.resourceId

@description('The name of the Managed DevOps Pool')
output managedPoolName string = managedDevOpsPool.outputs.name

@description('The resource ID of the Managed DevOps Pool')
output managedPoolResourceId string = managedDevOpsPool.outputs.resourceId

@description('The subnet resource ID where pool agents are deployed')
output poolSubnetResourceId string = poolSubnetResourceId

@description('The maximum concurrency (agent count) of the pool')
output poolMaximumConcurrency int = poolMaximumConcurrency

@description('Scale-to-zero enabled status')
output scaleToZeroEnabled bool = enableScaleToZero
