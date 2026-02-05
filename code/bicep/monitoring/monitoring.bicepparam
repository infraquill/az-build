using 'monitoring.bicep'

// ============================================================================
// MONITORING INFRASTRUCTURE PARAMETERS
// Default values for centralized monitoring infrastructure deployment
// ============================================================================
// Parameter Placement Strategy:
// - Stable organization-wide defaults are defined here (bicepparam)
// - String values that need organization-wide updates go in variable groups
// - Values that change per run are pipeline parameters
// ============================================================================

// ============================================================================
// CORE NAMING PARAMETERS
// These identify the monitoring workload and follow naming conventions
// ============================================================================

param projectName = 'landing-zone'

param workloadAlias = 'monitoring'

param environment = 'live'

param locationCode = 'cac'

param instanceNumber = '01'

param location = 'canadacentral'

// ============================================================================
// WORKSPACE CONFIGURATION
// Stable defaults for Log Analytics workspace configuration
// ============================================================================

param logAnalyticsWorkspaceResourceId = ''

// ============================================================================
// ACTION GROUP CONFIGURATION
// Organization-wide defaults for alert notifications
// Email/SMS receivers are passed from variable groups at deployment time
// ============================================================================

// Name suffix for the action group
param actionGroupNameSuffix = 'monitoring-alerts'

// Short name for the action group (max 12 characters)
param actionGroupShortName = 'mon-alerts'

// Email receivers - populated from variable group at deployment time
// Format: [{ name: 'Receiver Name', emailAddress: 'email@example.com', useCommonAlertSchema: true }]
param actionGroupEmailReceivers = []

// SMS receivers - populated from variable group at deployment time
// Format: [{ name: 'Receiver Name', countryCode: '1', phoneNumber: '5551234567' }]
param actionGroupSmsReceivers = []

// ============================================================================
// ALERT CONFIGURATION
// Organization-wide defaults for monitoring alerts
// ============================================================================

// Enable or disable alert rule deployment
param enableAlerts = true

// Default alert severity (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)
param alertSeverity = 2

// Threshold for data ingestion alert in GB per day
param dataIngestionThresholdGb = 100

// Evaluation frequency for alerts (ISO 8601 duration format)
param alertEvaluationFrequency = 'PT5M'

// Window size for alert evaluation (ISO 8601 duration format)
param alertWindowSize = 'PT15M'

// ============================================================================
// OWNERSHIP AND MANAGEMENT
// ============================================================================

param owner = 'platform-team@arcnovus.net'

param managedBy = 'Bicep'
