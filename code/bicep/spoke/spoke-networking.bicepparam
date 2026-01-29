using 'spoke-networking.bicep'

// ============================================================================
// SPOKE NETWORKING INFRASTRUCTURE PARAMETERS
// Default values for spoke networking infrastructure deployment
// ============================================================================

// Core naming parameters
// These identify the workload/project and its environment
param workloadAlias = 'example-workload'

param environment = 'dev'

param locationCode = 'cac'

param instanceNumber = '001'

// Location
param location = 'canadacentral'

// Spoke VNet address space
// Ensure this does not overlap with hub or other spoke VNets
// If using IPAM, coordinate with hub IPAM pool
param spokeVnetAddressSpace = '10.1.0.0/16'

// Log Analytics Workspace from monitoring infrastructure
// This must be provided during deployment - get from monitoring infrastructure outputs
param logAnalyticsWorkspaceResourceId = ''

// Ownership and management
param owner = 'workload-team@organization.com'

param managedBy = 'Bicep'

// ============================================================================
// HUB INFRASTRUCTURE REFERENCES
// These values come from hub infrastructure deployment outputs
// ============================================================================

// The hub Private DNS Zone name (e.g., internal.organization.com)
param hubPrivateDnsZoneName = 'internal.organization.com'

// The resource ID of the hub Private DNS Zone
// Format: /subscriptions/{subId}/resourceGroups/{rgName}/providers/Microsoft.Network/privateDnsZones/{zoneName}
param hubPrivateDnsZoneResourceId = ''

// The resource group name where hub infrastructure is deployed
param hubResourceGroupName = 'rg-hub-live-cac-001'

// The subscription ID where hub infrastructure is deployed
param hubSubscriptionId = ''

// ============================================================================
// IPAM CONFIGURATION (Optional)
// Enable if hub has IPAM Pool configured and you want centralized IP management
// ============================================================================

// Enable IPAM static CIDR allocation
param enableIpamAllocation = false

// Hub AVNM name (required if enableIpamAllocation is true)
// Get from hub deployment outputs: avnm-hub-live-cac-001
param hubAvnmName = ''

// Hub IPAM Pool name (required if enableIpamAllocation is true)
// Get from hub deployment outputs: ipam-hub-live-cac-001
param hubIpamPoolName = ''

// ============================================================================
// SUBNET CONFIGURATION (Optional)
// Define custom subnets or leave empty to use default workload subnet
// ============================================================================

// Custom subnet definitions
// If empty, a default 'workload' subnet using the first /24 will be created
// Example custom subnets:
// param customSubnets = [
//   {
//     name: 'web'
//     addressPrefix: '10.1.0.0/24'
//   }
//   {
//     name: 'app'
//     addressPrefix: '10.1.1.0/24'
//   }
//   {
//     name: 'data'
//     addressPrefix: '10.1.2.0/24'
//   }
// ]
param customSubnets = []
