targetScope = 'managementGroup'

// ============================================================================
// DIAGNOSTIC SETTING MODULE
// ============================================================================
// Helper module to deploy Diagnostic Settings to a specific scope (Management Group).
// This module is required to switch the deployment context from the main orchestration
// file to the specific target Management Group.
// ============================================================================

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Diagnostic Settings Name.')
param diagnosticSettingsName string

@description('Log Analytics Workspace Resource ID.')
param logAnalyticsWorkspaceResourceId string

@description('Diagnostic settings logs configuration.')
param logs array

// ============================================================================
// RESOURCES
// ============================================================================

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
  }
}
