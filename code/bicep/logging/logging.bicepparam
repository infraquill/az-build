using 'logging.bicep'

// ============================================================================
// LOGGING PARAMETERS
// ============================================================================

param projectName = 'landing-zone'
param workloadAlias = 'logging'
param environment = 'live'
param locationCode = 'cac'
param instanceNumber = '01'
param location = 'canadacentral'
param owner = 'platform-team@organization.com'
param managedBy = 'Bicep'

// Configuration
param dataRetention = 60
param workspaceSku = 'PerGB2018'
