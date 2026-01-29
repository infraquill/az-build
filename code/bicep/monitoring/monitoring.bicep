targetScope = 'subscription'

// ============================================================================
// MONITORING INFRASTRUCTURE - CENTRALIZED LOG ANALYTICS AND ALERTING
// ============================================================================
// This module deploys centralized monitoring infrastructure including:
// - Log Analytics Workspace with configurable SKU and retention
// - Action Group for alert notifications
// - Metric alerts for workspace health monitoring
// - Scheduled query rules for log-based alerting
//
// Security Note - Control Plane vs Data Plane:
// The publicNetworkAccess property controls DATA PLANE access (querying logs,
// ingesting data). It does NOT affect CONTROL PLANE operations (ARM API).
// Microsoft-hosted DevOps agents can deploy/update resources via ARM API
// even with publicNetworkAccess set to 'Disabled'. Only data plane operations
// (log queries, data ingestion) would be restricted to private endpoints.
// ============================================================================

// ============================================================================
// CORE NAMING PARAMETERS
// ============================================================================

@description('Project name used in tagging conventions (e.g., monitoring, landing-zone)')
param projectName string

@description('The workload alias used in naming conventions (e.g., monitoring, hub, mngmnt)')
param workloadAlias string

@description('The environment (e.g., live, dev, test)')
param environment string

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string

@description('The Azure region for the Log Analytics workspace')
param location string = 'canadacentral'

// ============================================================================
// WORKSPACE CONFIGURATION PARAMETERS
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

@description('The capacity reservation level in GB/day. Required when workspaceSku is CapacityReservation. Valid values: 100, 200, 300, 400, 500, 1000, 2000, 5000')
@allowed([
  100
  200
  300
  400
  500
  1000
  2000
  5000
])
param capacityReservationLevel int = 100

@description('Daily quota for data ingestion in GB. Set to -1 for unlimited.')
param dailyQuotaGb int = -1

// ============================================================================
// SECURITY CONFIGURATION PARAMETERS
// ============================================================================

@description('Public network access for data plane operations (querying logs, ingesting data). Does NOT affect ARM API deployments - those always work. Default: Enabled for log query convenience.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

// ============================================================================
// ACTION GROUP CONFIGURATION PARAMETERS
// ============================================================================

@description('Name suffix for the action group')
param actionGroupNameSuffix string = 'monitoring-alerts'

@description('Short name for the action group (max 12 characters)')
@maxLength(12)
param actionGroupShortName string = 'mon-alerts'

@description('Email addresses for alert notifications (array of email receiver objects)')
param actionGroupEmailReceivers array = []

@description('SMS receivers for alert notifications (array of SMS receiver objects)')
param actionGroupSmsReceivers array = []

// ============================================================================
// ALERT CONFIGURATION PARAMETERS
// ============================================================================

@description('Enable deployment of alert rules')
param enableAlerts bool = true

@description('Severity level for alerts (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)')
@minValue(0)
@maxValue(4)
param alertSeverity int = 2

@description('Threshold for data ingestion alert in GB per day')
param dataIngestionThresholdGb int = 100

@description('Evaluation frequency for alerts in ISO 8601 duration format')
param alertEvaluationFrequency string = 'PT5M'

@description('Window size for alert evaluation in ISO 8601 duration format')
param alertWindowSize string = 'PT15M'

// ============================================================================
// OWNERSHIP AND MANAGEMENT PARAMETERS
// ============================================================================

@description('The owner of the monitoring infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

// ============================================================================
// COMPUTED VARIABLES
// ============================================================================

// Construct workspace name following naming convention: law-<workloadAlias>-<environment>-<loc>-<instance>
var workspaceName = 'law-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Resource group name for monitoring resources
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Action group name
var actionGroupName = 'ag-${workloadAlias}-${actionGroupNameSuffix}-${environment}-${locationCode}-${instanceNumber}'

// Common tags for all resources
var commonTags = {
  Project: projectName
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// SKU configuration - only set capacityReservationLevel when using CapacityReservation SKU
var skuName = workspaceSku
var workspaceCapacityReservationLevel = workspaceSku == 'CapacityReservation' ? capacityReservationLevel : null

// ============================================================================
// RESOURCE GROUP
// ============================================================================

// Deploy resource group for monitoring resources
resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

// Deploy Log Analytics Workspace using AVM
// Note: Using version 0.14.0 - check Azure/bicep-registry-modules for latest version
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.0' = {
  name: 'deploy-${workspaceName}'
  scope: monitoringResourceGroup
  params: {
    name: workspaceName
    location: location
    skuName: skuName
    skuCapacityReservationLevel: workspaceCapacityReservationLevel
    dataRetention: dataRetention
    dailyQuotaGb: dailyQuotaGb
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: publicNetworkAccess
    tags: commonTags
  }
}

// ============================================================================
// ACTION GROUP
// ============================================================================

// Deploy Action Group for alert notifications using AVM
// Note: Using version 0.4.0 - check Azure/bicep-registry-modules for latest version
module actionGroup 'br/public:avm/res/insights/action-group:0.4.0' = {
  name: 'deploy-${actionGroupName}'
  scope: monitoringResourceGroup
  params: {
    name: actionGroupName
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: actionGroupEmailReceivers
    smsReceivers: actionGroupSmsReceivers
    tags: commonTags
  }
}

// ============================================================================
// LOG-BASED ALERTS (Scheduled Query Rules)
// Note: Log Analytics workspaces don't support metric alerts for ingestion/availability.
// We use KQL queries against the Usage table instead.
// ============================================================================

// Alert: Data Ingestion Volume
// Triggers when daily data ingestion exceeds the configured threshold
module dataIngestionAlert 'br/public:avm/res/insights/scheduled-query-rule:0.3.0' = if (enableAlerts) {
  name: 'deploy-alert-data-ingestion-${workspaceName}'
  scope: monitoringResourceGroup
  params: {
    name: 'alert-data-ingestion-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
    alertDescription: 'Alert when Log Analytics workspace data ingestion exceeds ${dataIngestionThresholdGb} GB per day'
    enabled: true
    kind: 'LogAlert'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    evaluationFrequency: alertEvaluationFrequency
    windowSize: 'P1D' // 1 day window for daily ingestion
    severity: alertSeverity
    criterias: {
      allOf: [
        {
          // Note: Using string concatenation because triple-quoted strings don't support interpolation
          query: 'Usage | where TimeGenerated > ago(1d) | where IsBillable == true | summarize TotalGB = sum(Quantity) / 1000 | where TotalGB > ${dataIngestionThresholdGb}'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: [
      actionGroup.outputs.resourceId
    ]
    autoMitigate: true
    tags: commonTags
  }
}

// Alert: Workspace Availability (Heartbeat-based)
// Triggers when no heartbeat data is received, indicating potential availability issues
module workspaceAvailabilityAlert 'br/public:avm/res/insights/scheduled-query-rule:0.3.0' = if (enableAlerts) {
  name: 'deploy-alert-availability-${workspaceName}'
  scope: monitoringResourceGroup
  params: {
    name: 'alert-availability-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
    alertDescription: 'Alert when Log Analytics workspace has no recent data ingestion (potential availability issue)'
    enabled: true
    kind: 'LogAlert'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    evaluationFrequency: alertEvaluationFrequency
    windowSize: alertWindowSize
    severity: 1 // Error severity for availability issues
    criterias: {
      allOf: [
        {
          query: 'Usage | where TimeGenerated > ago(1h) | summarize RecordCount = count() | where RecordCount == 0'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: [
      actionGroup.outputs.resourceId
    ]
    autoMitigate: true
    tags: commonTags
  }
}

// ============================================================================
// SCHEDULED QUERY RULES (LOG-BASED ALERTS)
// ============================================================================

// Alert: Query Throttling Detection
// Triggers when queries are being throttled due to rate limits
module queryThrottlingAlert 'br/public:avm/res/insights/scheduled-query-rule:0.3.0' = if (enableAlerts) {
  name: 'deploy-alert-throttling-${workspaceName}'
  scope: monitoringResourceGroup
  params: {
    name: 'alert-query-throttling-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
    alertDescription: 'Alert when Log Analytics queries are being throttled'
    enabled: true
    kind: 'LogAlert'
    scopes: [
      logAnalyticsWorkspace.outputs.resourceId
    ]
    evaluationFrequency: alertEvaluationFrequency
    windowSize: 'PT1H'
    severity: alertSeverity
    criterias: {
      allOf: [
        {
          query: '''
            LAQueryLogs
            | where ResponseCode == 429
            | summarize ThrottledQueries = count() by bin(TimeGenerated, 5m)
            | where ThrottledQueries > 0
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: [
      actionGroup.outputs.resourceId
    ]
    autoMitigate: true
    tags: commonTags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The resource ID of the Log Analytics workspace')
output workspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The name of the Log Analytics workspace')
output workspaceName string = logAnalyticsWorkspace.outputs.name

@description('The name of the resource group')
output resourceGroupName string = monitoringResourceGroup.name

@description('The resource ID of the Action Group')
output actionGroupResourceId string = actionGroup.outputs.resourceId

@description('The name of the Action Group')
output actionGroupName string = actionGroup.outputs.name

@description('The resource ID of the data ingestion alert (empty if alerts disabled)')
output dataIngestionAlertResourceId string = enableAlerts ? dataIngestionAlert!.outputs.resourceId : ''

@description('The resource ID of the availability alert (empty if alerts disabled)')
output availabilityAlertResourceId string = enableAlerts ? workspaceAvailabilityAlert!.outputs.resourceId : ''

@description('The resource ID of the query throttling alert (empty if alerts disabled)')
output queryThrottlingAlertResourceId string = enableAlerts ? queryThrottlingAlert!.outputs.resourceId : ''
