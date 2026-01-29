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

@description('Location for the deployment metadata.')
#disable-next-line no-unused-params
param location string = 'canadacentral'

@description('Management Group ID for the top level management group.')
@minLength(2)
@maxLength(36)
param topLevelManagementGroupId string = 'alz'

@description('Prefix for child management groups.')
@maxLength(36)
param childManagementGroupPrefix string = 'mg'

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

// ============================================================================
// COMPUTED VARIABLES
// ============================================================================

var mgIds = {
  intRoot: topLevelManagementGroupId
  platform: '${childManagementGroupPrefix}-platform'
  landingZones: '${childManagementGroupPrefix}-landingzones'
  decommissioned: '${childManagementGroupPrefix}-decommissioned'
  sandbox: '${childManagementGroupPrefix}-sandbox'
}

// Used if landingZoneMgAlzDefaultsEnable == true
var landingZoneMgChildrenAlzDefault = {
  landingZonesCorp: '${childManagementGroupPrefix}-landingzones-corp'
  landingZonesOnline: '${childManagementGroupPrefix}-landingzones-online'
}

// Used if platformMgAlzDefaultsEnable == true
var platformMgChildrenAlzDefault = {
  platformManagement: '${childManagementGroupPrefix}-platform-management'
  platformSecurity: '${childManagementGroupPrefix}-platform-security'
  platformConnectivity: '${childManagementGroupPrefix}-platform-connectivity'
  platformIdentity: '${childManagementGroupPrefix}-platform-identity'
}

// Used if landingZoneMgConfidentialEnable == true
var landingZoneMgChildrenConfidential = {
  landingZonesConfidentialCorp: '${childManagementGroupPrefix}-landingzones-confidential-corp'
  landingZonesConfidentialOnline: '${childManagementGroupPrefix}-landingzones-confidential-online'
}

// Used if landingZoneMgConfidentialEnable not empty
var landingZoneMgCustomChildren = [
  for customMg in landingZoneMgChildren: {
    mgId: '${childManagementGroupPrefix}-landingzones-${customMg}'
  }
]

// Used if landingZoneMgConfidentialEnable not empty
var platformMgCustomChildren = [
  for customMg in platformMgChildren: {
    mgId: '${childManagementGroupPrefix}-platform-${customMg}'
  }
]

// Build final object based on input parameters for default and confidential child MGs of LZs
var landingZoneMgDefaultChildrenUnioned = landingZoneMgAlzDefaultsEnable
  ? (landingZoneMgConfidentialEnable
      ? union(landingZoneMgChildrenAlzDefault, landingZoneMgChildrenConfidential)
      : landingZoneMgChildrenAlzDefault)
  : (landingZoneMgConfidentialEnable ? landingZoneMgChildrenConfidential : {})

// Build final object based on input parameters for default child MGs of Platform LZs
var platformMgDefaultChildrenUnioned = platformMgAlzDefaultsEnable ? platformMgChildrenAlzDefault : {}

// ============================================================================
// RESOURCE DEPLOYMENTS
// ============================================================================

// 1. Root & Core Management Groups
resource mgScope_root 'Microsoft.Management/managementGroups@2021-04-01' existing = [
  for item in items(mgIds): {
    scope: tenant()
    name: item.value
  }
]

module diag_root 'modules/diagnostic-setting.bicep' = [
  for (item, i) in items(mgIds): {
    scope: mgScope_root[i]
    name: 'deploy-diag-root-${item.key}'
    params: {
      diagnosticSettingsName: diagnosticSettingsName
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
  }
]

// 2. Default Children Landing Zone Management Groups
resource mgScope_lz 'Microsoft.Management/managementGroups@2021-04-01' existing = [
  for item in items(landingZoneMgDefaultChildrenUnioned): {
    scope: tenant()
    name: item.value
  }
]

module diag_lz 'modules/diagnostic-setting.bicep' = [
  for (item, i) in items(landingZoneMgDefaultChildrenUnioned): {
    scope: mgScope_lz[i]
    name: 'deploy-diag-lz-${item.key}'
    params: {
      diagnosticSettingsName: diagnosticSettingsName
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
  }
]

// 3. Default Children Platform Management Groups
resource mgScope_platform 'Microsoft.Management/managementGroups@2021-04-01' existing = [
  for item in items(platformMgDefaultChildrenUnioned): {
    scope: tenant()
    name: item.value
  }
]

module diag_platform 'modules/diagnostic-setting.bicep' = [
  for (item, i) in items(platformMgDefaultChildrenUnioned): {
    scope: mgScope_platform[i]
    name: 'deploy-diag-platform-${item.key}'
    params: {
      diagnosticSettingsName: diagnosticSettingsName
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
  }
]

// 4. Custom Children Landing Zone Management Groups
resource mgScope_customLz 'Microsoft.Management/managementGroups@2021-04-01' existing = [
  for item in landingZoneMgCustomChildren: {
    scope: tenant()
    name: item.mgId
  }
]

module diag_customLz 'modules/diagnostic-setting.bicep' = [
  for (item, i) in landingZoneMgCustomChildren: {
    scope: mgScope_customLz[i]
    name: 'deploy-diag-customLz-${i}'
    params: {
      diagnosticSettingsName: diagnosticSettingsName
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
  }
]

// 5. Custom Children Platform Management Groups
resource mgScope_customPlatform 'Microsoft.Management/managementGroups@2021-04-01' existing = [
  for item in platformMgCustomChildren: {
    scope: tenant()
    name: item.mgId
  }
]

module diag_customPlatform 'modules/diagnostic-setting.bicep' = [
  for (item, i) in platformMgCustomChildren: {
    scope: mgScope_customPlatform[i]
    name: 'deploy-diag-customPlatform-${i}'
    params: {
      diagnosticSettingsName: diagnosticSettingsName
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
  }
]
