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

param instanceNumber = '001'

param location = 'canadacentral'

// ============================================================================
// WORKSPACE CONFIGURATION
// Stable defaults for Log Analytics workspace configuration
// ============================================================================

// Data retention in days (30-730)
param dataRetention = 60

// SKU: PerGB2018 (Pay-As-You-Go) or CapacityReservation
// PerGB2018 SKU provides 5 GB/day of free data ingestion (shared across all PerGB2018 workspaces in the same billing account), 
// unlimited data retention (billed per GB after the free allowance).
// For official details see: https://docs.microsoft.com/azure/azure-monitor/logs/storage-ingestion#ingestion-costs
param workspaceSku = 'PerGB2018'

// Capacity reservation level in GB/day (only used when workspaceSku is CapacityReservation)
// Valid values: 100, 200, 300, 400, 500, 1000, 2000, 5000
param capacityReservationLevel = 100

// Daily quota for data ingestion in GB (-1 for unlimited)
param dailyQuotaGb = -1

// ============================================================================
// SECURITY CONFIGURATION
// Defaults that support Microsoft-hosted DevOps agent deployments
// ============================================================================

// Public network access for data plane operations (querying logs, ingesting data)
// Note: This does NOT affect ARM API deployments - those always work regardless of this setting
// 'Enabled' allows log queries from any network
// 'Disabled' restricts data plane to private endpoints only (deployment still works)
param publicNetworkAccess = 'Enabled'

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
