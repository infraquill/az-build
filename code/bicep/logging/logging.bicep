targetScope = 'subscription'

// ============================================================================
// LOGGING INFRASTRUCTURE
// ============================================================================
// Deploys the core logging infrastructure:
// - Log Analytics Workspace (centralized logs)
// - Automation Account (linked to workspace for solutions/updates)
// ============================================================================

// ============================================================================
// NAMING PARAMETERS
// ============================================================================

@description('Project name used in tagging conventions')
param projectName string

@description('The workload alias used in naming conventions (e.g., logging, management)')
param workloadAlias string = 'logging'

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string

@description('The Azure region for the resources')
param location string = 'canadacentral'

@description('The owner of the infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// ============================================================================
// CONFIGURATION PARAMETERS
// ============================================================================

@description('Number of days for data retention (30-730 days)')
@minValue(30)
@maxValue(730)
param dataRetention int = 60

@description('The SKU for the Log Analytics workspace.')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param workspaceSku string = 'PerGB2018'

// ============================================================================
// VARIABLES
// ============================================================================

var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var workspaceName = 'law-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var automationAccountName = 'aa-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

var commonTags = {
  Project: projectName
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource loggingResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.0' = {
  name: 'deploy-${workspaceName}'
  scope: loggingResourceGroup
  params: {
    name: workspaceName
    location: location
    skuName: workspaceSku
    dataRetention: dataRetention
    tags: commonTags
  }
}

// ============================================================================
// AUTOMATION ACCOUNT
// ============================================================================

module automationAccount 'br/public:avm/res/automation/automation-account:0.4.0' = {
  name: 'deploy-${automationAccountName}'
  scope: loggingResourceGroup
  params: {
    name: automationAccountName
    location: location
    skuName: 'Basic'
    tags: commonTags
    // Link to Log Analytics Workspace (optional but recommended for Update Management)
    // Note: AVM might abstract the linking via specific parameters or we assume separate management for now.
    // Standard integration usually involves linked services, but basic deployment is sufficient for standard logging module.
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the Log Analytics workspace')
output workspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The name of the Log Analytics workspace')
output workspaceName string = logAnalyticsWorkspace.outputs.name

@description('The resource ID of the Automation Account')
output automationAccountResourceId string = automationAccount.outputs.resourceId

@description('The resource ID of the resource group')
output resourceGroupName string = loggingResourceGroup.name
