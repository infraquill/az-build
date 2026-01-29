using 'devcenter.bicep'

// ============================================================================
// DEVCENTER INFRASTRUCTURE PARAMETERS
// Configures DevCenter resources required for Managed DevOps Pools
// Note: DevCenter is typically deployed once per organization
// ============================================================================

// Naming and location
param workloadAlias = 'devcenter'
param environment = 'live'
param locationCode = 'cac'
param instanceNumber = '001'
param location = 'canadacentral'

// Ownership
param owner = 'cloudops-team@organization.com' // Placeholder: Update with actual owner

// Spoke networking references
// The subnet where Managed DevOps Pool agents will be deployed
param subnetResourceId = '/subscriptions/YOUR_CLOUDOPS_SUBSCRIPTION_ID/resourceGroups/rg-cloudops-live-cac-001/providers/Microsoft.Network/virtualNetworks/vnet-cloudops-live-cac-001/subnets/workload' // Placeholder

// Monitoring
param logAnalyticsWorkspaceResourceId = '/subscriptions/YOUR_MONITORING_SUBSCRIPTION_ID/resourceGroups/rg-monitoring-live-cac-001/providers/Microsoft.OperationalInsights/workspaces/log-monitoring-live-cac-001' // Placeholder
