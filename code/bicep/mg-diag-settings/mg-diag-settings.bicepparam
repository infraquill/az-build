using './mg-diag-settings.bicep'

// ============================================================================
// MANAGEMENT GROUP DIAGNOSTIC SETTINGS PARAMETERS
// ============================================================================
// This file defines the parameters for enabling Diagnostic Settings across the
// Management Group hierarchy.
// ============================================================================

// ============================================================================
// HIERARCHY CONFIGURATION
// ============================================================================

// Location for the deployment metadata
param location = 'canadacentral'

// Management Group ID for the top level management group
param topLevelManagementGroupId = 'contoso'

// Prefix for child management groups (e.g. 'mg')
param childManagementGroupPrefix = 'mg'

// ============================================================================
// MANAGEMENT GROUP CHILDREN CONFIGURATION
// Define custom children management groups below if needed
// ============================================================================

// Array of strings to allow additional or different child Management Groups of the Landing Zones Management Group
param landingZoneMgChildren = []

// Array of strings to allow additional or different child Management Groups of the Platform Management Group
param platformMgChildren = []

// ============================================================================
// DIAGNOSTIC DESTINATION CONFIGURATION
// ============================================================================

// Log Analytics Workspace Resource ID where metrics/logs will be sent
// Note: This should be supplied at deployment time if dynamic
param logAnalyticsWorkspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/placeholder-rg/providers/Microsoft.OperationalInsights/workspaces/placeholder-workspace'

// Name of the Diagnostic Setting resource
param diagnosticSettingsName = 'toLa'

// ============================================================================
// DEPLOYMENT SCOPE TOGGLES
// Control which branches of the hierarchy receive diagnostic settings
// ============================================================================

// Deploys Diagnostic Settings on Corp & Online Management Groups beneath Landing Zones Management Group
param landingZoneMgAlzDefaultsEnable = true

// Deploys Diagnostic Settings on Management, Security, Connectivity and Identity Management Groups beneath Platform Management Group
param platformMgAlzDefaultsEnable = true

// Deploys Diagnostic Settings on Confidential Corp & Confidential Online Management Groups beneath Landing Zones Management Group
param landingZoneMgConfidentialEnable = false

// ============================================================================
// TELEMETRY
// ============================================================================
