using 'hub.bicep'

// ============================================================================
// HUB INFRASTRUCTURE PARAMETERS
// Default values for hub networking infrastructure deployment
// ============================================================================

// Core naming parameters
param workloadAlias = 'hub'

param environment = 'live'

param locationCode = 'cac'

param instanceNumber = '001'

// Location
param location = 'canadacentral'

// Private DNS Zone - custom internal domain
param privateDnsZoneName = 'internal.organization.com'

// Hub VNet address space
param hubVnetAddressSpace = '10.0.0.0/16'

// Log Analytics Workspace from monitoring infrastructure
// This must be provided during deployment
param logAnalyticsWorkspaceResourceId = ''

// Ownership and management
param owner = 'platform-team@organization.com'

param managedBy = 'Bicep'

// AVNM Management Group scope
param avnmManagementGroupId = 'mg-connectivity'

// ============================================================================
// OPTIONAL RESOURCES - All disabled by default
// ============================================================================

// Application Gateway with WAF
param enableAppGatewayWAF = false

// Azure Front Door (Standard)
param enableFrontDoor = false

// VPN Gateway with P2S configuration
param enableVpnGateway = false

// Azure Firewall
param enableAzureFirewall = false

// Azure DDoS Protection
param enableDDoSProtection = false

// Private DNS Resolver
param enableDnsResolver = false

// IPAM Pool
param enableIpamPool = false
param ipamPoolAddressSpace = '10.0.0.0/8'
param ipamPoolDescription = 'Centralized IPAM pool for hub and spoke networks'

// ============================================================================
// OPTIONAL RESOURCE CONFIGURATION
// ============================================================================

// VPN Gateway P2S client address pool
param vpnClientAddressPoolPrefix = '172.16.0.0/24'

// Azure Firewall SKU tier
param azureFirewallTier = 'Standard'

// Key Vault administrator principal ID (Object ID)
// Provide during deployment to grant Key Vault Administrator role
param keyVaultAdminPrincipalId = ''
