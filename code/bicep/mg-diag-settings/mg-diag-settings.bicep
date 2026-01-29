targetScope = 'managementGroup'

// ============================================================================
// MANAGEMENT GROUP DIAGNOSTIC SETTINGS
// ============================================================================
// Orchestration module that helps enable Diagnostic Settings on the Management
// Group hierarchy as was defined during the deployment of the Management Group module
// ============================================================================

// ============================================================================
// HIERARCHY PARAMETERS
// ============================================================================

@description('Prefix used for the management group hierarchy.')
@minLength(2)
@maxLength(10)
param topLevelManagementGroupPrefix string = 'alz'

@description('Optional suffix for the management group hierarchy. This suffix will be appended to management group names/IDs. Include a preceding dash if required. Example: -suffix')
@maxLength(10)
param topLevelManagementGroupSuffix string = ''

// ============================================================================
// CUSTOM CHILDREN PARAMETERS
// ============================================================================

@description('Array of strings to allow additional or different child Management Groups of the Landing Zones Management Group.')
param landingZoneMgChildren array = []

@description('Array of strings to allow additional or different child Management Groups of the Platform Management Group.')
param platformMgChildren array = []

// ============================================================================
// DIAGNOSTIC SETTINGS PARAMETERS
// ============================================================================

@description('Log Analytics Workspace Resource ID.')
param logAnalyticsWorkspaceResourceId string

@description('Diagnostic Settings Name.')
param diagnosticSettingsName string = 'toLa'

// ============================================================================
// DEPLOYMENT SCOPE TOGGLES
// ============================================================================

@description('Deploys Diagnostic Settings on Corp & Online Management Groups beneath Landing Zones Management Group if set to true.')
param landingZoneMgAlzDefaultsEnable bool = true

@description('Deploys Diagnostic Settings on Management, Security, Connectivity and Identity Management Groups beneath Platform Management Group if set to true.')
param platformMgAlzDefaultsEnable bool = true

@description('Deploys Diagnostic Settings on Confidential Corp & Confidential Online Management Groups beneath Landing Zones Management Group if set to true.')
param landingZoneMgConfidentialEnable bool = false

// ============================================================================
// TELEMETRY
// ============================================================================

@description('Set Parameter to true to Opt-out of deployment telemetry.')
param telemetryOptOut bool = false

// ============================================================================
// COMPUTED VARIABLES
// ============================================================================

var mgIds = {
  intRoot: '${topLevelManagementGroupPrefix}${topLevelManagementGroupSuffix}'
  platform: '${topLevelManagementGroupPrefix}-platform${topLevelManagementGroupSuffix}'
  landingZones: '${topLevelManagementGroupPrefix}-landingzones${topLevelManagementGroupSuffix}'
  decommissioned: '${topLevelManagementGroupPrefix}-decommissioned${topLevelManagementGroupSuffix}'
  sandbox: '${topLevelManagementGroupPrefix}-sandbox${topLevelManagementGroupSuffix}'
}

// Used if landingZoneMgAlzDefaultsEnable == true
var landingZoneMgChildrenAlzDefault = {
  landingZonesCorp: '${topLevelManagementGroupPrefix}-landingzones-corp${topLevelManagementGroupSuffix}'
  landingZonesOnline: '${topLevelManagementGroupPrefix}-landingzones-online${topLevelManagementGroupSuffix}'
}

// Used if platformMgAlzDefaultsEnable == true
var platformMgChildrenAlzDefault = {
  platformManagement: '${topLevelManagementGroupPrefix}-platform-management${topLevelManagementGroupSuffix}'
  platformSecurity: '${topLevelManagementGroupPrefix}-platform-security${topLevelManagementGroupSuffix}'
  platformConnectivity: '${topLevelManagementGroupPrefix}-platform-connectivity${topLevelManagementGroupSuffix}'
  platformIdentity: '${topLevelManagementGroupPrefix}-platform-identity${topLevelManagementGroupSuffix}'
}

// Used if landingZoneMgConfidentialEnable == true
var landingZoneMgChildrenConfidential = {
  landingZonesConfidentialCorp: '${topLevelManagementGroupPrefix}-landingzones-confidential-corp${topLevelManagementGroupSuffix}'
  landingZonesConfidentialOnline: '${topLevelManagementGroupPrefix}-landingzones-confidential-online${topLevelManagementGroupSuffix}'
}

// Used if landingZoneMgConfidentialEnable not empty
var landingZoneMgCustomChildren = [for customMg in landingZoneMgChildren: {
  mgId: '${topLevelManagementGroupPrefix}-landingzones-${customMg}${topLevelManagementGroupSuffix}'
}]

// Used if landingZoneMgConfidentialEnable not empty
var platformMgCustomChildren = [for customMg in platformMgChildren: {
  mgId: '${topLevelManagementGroupPrefix}-platform-${customMg}${topLevelManagementGroupSuffix}'
}]

// Build final object based on input parameters for default and confidential child MGs of LZs
var landingZoneMgDefaultChildrenUnioned = (landingZoneMgAlzDefaultsEnable && landingZoneMgConfidentialEnable) ? union(landingZoneMgChildrenAlzDefault, landingZoneMgChildrenConfidential) : (landingZoneMgAlzDefaultsEnable && !landingZoneMgConfidentialEnable) ? landingZoneMgChildrenAlzDefault : (!landingZoneMgAlzDefaultsEnable && landingZoneMgConfidentialEnable) ? landingZoneMgChildrenConfidential : (!landingZoneMgAlzDefaultsEnable && !landingZoneMgConfidentialEnable) ? {} : {}

// Build final object based on input parameters for default child MGs of Platform LZs
var platformMgDefaultChildrenUnioned = (platformMgAlzDefaultsEnable) ? platformMgChildrenAlzDefault : (platformMgAlzDefaultsEnable) ? platformMgChildrenAlzDefault : (!platformMgAlzDefaultsEnable) ? {} : (!platformMgAlzDefaultsEnable) ? {} : {}

// Customer Usage Attribution Id
var cuaid = 'f49c8dfb-c0ce-4ee0-b316-5e4844474dd0'

// ============================================================================
// RESOURCE DEPLOYMENTS
// ============================================================================

// 1. Root & Core Management Groups
resource mgScope_root 'Microsoft.Management/managementGroups@2021-04-01' existing = [for item in items(mgIds): {
  name: item.value
}]

resource diag_root 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, i) in items(mgIds): {
  scope: mgScope_root[i]
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
    ]
  }
}]

// 2. Default Children Landing Zone Management Groups
resource mgScope_lz 'Microsoft.Management/managementGroups@2021-04-01' existing = [for item in items(landingZoneMgDefaultChildrenUnioned): {
  name: item.value
}]

resource diag_lz 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, i) in items(landingZoneMgDefaultChildrenUnioned): {
  scope: mgScope_lz[i]
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
    ]
  }
}]

// 3. Default Children Platform Management Groups
resource mgScope_platform 'Microsoft.Management/managementGroups@2021-04-01' existing = [for item in items(platformMgDefaultChildrenUnioned): {
  name: item.value
}]

resource diag_platform 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, i) in items(platformMgDefaultChildrenUnioned): {
  scope: mgScope_platform[i]
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
    ]
  }
}]

// 4. Custom Children Landing Zone Management Groups
resource mgScope_customLz 'Microsoft.Management/managementGroups@2021-04-01' existing = [for item in landingZoneMgCustomChildren: {
  name: item.mgId
}]

resource diag_customLz 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, i) in landingZoneMgCustomChildren: {
  scope: mgScope_customLz[i]
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
    ]
  }
}]

// 5. Custom Children Platform Management Groups
resource mgScope_customPlatform 'Microsoft.Management/managementGroups@2021-04-01' existing = [for item in platformMgCustomChildren: {
  name: item.mgId
}]

resource diag_customPlatform 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (item, i) in platformMgCustomChildren: {
  scope: mgScope_customPlatform[i]
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
    ]
  }
}]

// Optional Deployment for Customer Usage Attribution
// module modCustomerUsageAttribution '../CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!telemetryOptOut) {
//   #disable-next-line no-loc-expr-outside-params
//   name: 'pid-${cuaid}-${uniqueString(deployment().location)}'
//   scope: managementGroup()
//   params: {}
// }
