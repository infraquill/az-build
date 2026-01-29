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

// Prefix used for the management group hierarchy (e.g. 'alz')
param parTopLevelManagementGroupPrefix = 'alz'

// Optional suffix for the management group hierarchy
param parTopLevelManagementGroupSuffix = ''

// ============================================================================
// MANAGEMENT GROUP CHILDREN CONFIGURATION
// Define custom children management groups below if needed
// ============================================================================

// Array of strings to allow additional or different child Management Groups of the Landing Zones Management Group
param parLandingZoneMgChildren = []

// Array of strings to allow additional or different child Management Groups of the Platform Management Group
param parPlatformMgChildren = []

// ============================================================================
// DIAGNOSTIC DESTINATION CONFIGURATION
// ============================================================================

// Log Analytics Workspace Resource ID where metrics/logs will be sent
// Note: This should be supplied at deployment time if dynamic
param parLogAnalyticsWorkspaceResourceId = ''

// Name of the Diagnostic Setting resource
param parDiagnosticSettingsName = 'toLa'

// ============================================================================
// DEPLOYMENT SCOPE TOGGLES
// Control which branches of the hierarchy receive diagnostic settings
// ============================================================================

// Deploys Diagnostic Settings on Corp & Online Management Groups beneath Landing Zones Management Group
param parLandingZoneMgAlzDefaultsEnable = true

// Deploys Diagnostic Settings on Management, Security, Connectivity and Identity Management Groups beneath Platform Management Group
param parPlatformMgAlzDefaultsEnable = true

// Deploys Diagnostic Settings on Confidential Corp & Confidential Online Management Groups beneath Landing Zones Management Group
param parLandingZoneMgConfidentialEnable = false

// ============================================================================
// TELEMETRY
// ============================================================================

// Set to true to Opt-out of deployment telemetry
param parTelemetryOptOut = false
