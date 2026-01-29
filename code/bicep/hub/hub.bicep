targetScope = 'subscription'

// ============================================================================
// HUB INFRASTRUCTURE
// Deploys hub networking infrastructure including:
// - Resource Group
// - Network Watcher
// - Private DNS Zone
// - Azure Virtual Network Manager (AVNM)
// - Hub Virtual Network with standard subnets
// - Optional: Application Gateway+WAF, Azure Front Door, VPN Gateway, Azure Firewall, DDoS Protection
// All diagnostic settings send logs/metrics to the common Log Analytics Workspace
// ============================================================================

// ============================================================================
// PARAMETERS
// ============================================================================

@description('The workload alias used in naming conventions (e.g., hub, mngmnt)')
param workloadAlias string = 'hub'

@description('The environment (e.g., live, dev, test)')
param environment string = 'live'

@description('The location code for naming convention (e.g., cac)')
param locationCode string = 'cac'

@description('The instance number for naming convention')
param instanceNumber string = '001'

@description('The Azure region for the hub resources')
param location string = 'canadacentral'

@description('The private DNS zone name for internal resources. (e.g. internal.organization.com)')
param privateDnsZoneName string

@description('The address space for the hub virtual network. Must be at least /18 to accommodate all subnets. Default /16 provides room for growth. Subnets are calculated as follows: GatewaySubnet /24 at index 0, AzureFirewallSubnet /24 at index 1, AppGatewaySubnet /24 at index 2, Management /24 at index 3, AzureBastionSubnet /26 at index 16, DnsResolverInbound /28 at index 80.')
param hubVnetAddressSpace string = '10.0.0.0/16'

@description('Resource ID of the Log Analytics Workspace from monitoring infrastructure')
param logAnalyticsWorkspaceResourceId string

@description('The owner of the hub infrastructure')
param owner string

@description('What manages this infrastructure (e.g., Bicep, Terraform)')
param managedBy string = 'Bicep'

@description('The management group ID for AVNM scope')
param avnmManagementGroupId string = 'mg-connectivity'

// Optional resource flags
@description('Enable Azure Application Gateway with WAF')
param enableAppGatewayWAF bool = false

@description('Enable Azure Front Door (Standard)')
param enableFrontDoor bool = false

@description('Enable VPN Gateway with P2S configuration')
param enableVpnGateway bool = false

@description('Enable Azure Firewall')
param enableAzureFirewall bool = false

@description('Enable Azure DDoS Protection')
param enableDDoSProtection bool = false

@description('Enable Private DNS Resolver')
param enableDnsResolver bool = false

@description('Enable IPAM Pool for centralized IP address management')
param enableIpamPool bool = false

@description('The IP address range for the IPAM pool. Must be a supernet that contains the hubVnetAddressSpace. (e.g., 10.0.0.0/8 for large organizations where hub uses 10.0.0.0/16)')
param ipamPoolAddressSpace string = '10.0.0.0/8'

@description('Description for the IPAM pool')
param ipamPoolDescription string = 'Centralized IPAM pool for hub and spoke networks'

// VPN Gateway P2S configuration
@description('VPN client address pool for P2S connections')
param vpnClientAddressPoolPrefix string = '172.16.0.0/24'

@description('Azure Firewall SKU tier (Standard or Premium)')
@allowed(['Standard', 'Premium'])
param azureFirewallTier string = 'Standard'

@description('Principal ID (Object ID) to grant Key Vault Administrator role. Leave empty to skip role assignment.')
param keyVaultAdminPrincipalId string = ''

// ============================================================================
// VARIABLES
// ============================================================================

// Naming convention variables
var resourceGroupName = 'rg-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var networkWatcherName = 'NetworkWatcher_${locationCode}'
var avnmName = 'avnm-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var hubVnetName = 'vnet-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Optional resource names
var appGatewayName = 'agw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var appGatewayPipName = 'pip-agw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var frontDoorName = 'afd-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var vpnGatewayName = 'vpngw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var vpnGatewayPipName = 'pip-vpngw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var azureFirewallName = 'afw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var azureFirewallPipName = 'pip-afw-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var azureFirewallPolicyName = 'afwp-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var ddosProtectionPlanName = 'ddos-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var keyVaultName = 'kv-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var dnsResolverName = 'dnspr-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var ipamPoolName = 'ipam-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var ipamStaticCidrName = 'ipamsc-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var privateDnsZoneVnetLinkName = 'pdnslnk-${workloadAlias}-to-${hubVnetName}'
var dnsResolverInboundEndpointName = 'in-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'
var appGatewayWafPolicyName = 'wafp-${workloadAlias}-${environment}-${locationCode}-${instanceNumber}'

// Common tags
var commonTags = {
  Project: workloadAlias
  Environment: environment
  Owner: owner
  ManagedBy: managedBy
}

// Subnet configurations
// Note: hubVnetAddressSpace must be at least /18 to support all subnet indices
// cidrSubnet(base, newBits, netNum) calculates subnets based on the base address space
// Example with 10.0.0.0/16:
//   - /24 subnets: 256 available (indices 0-255)
//   - /26 subnets: 1024 available (indices 0-1023)
//   - /28 subnets: 4096 available (indices 0-4095)
var gatewaySubnetPrefix = cidrSubnet(hubVnetAddressSpace, 24, 0) // 10.0.0.0/24
var azureFirewallSubnetPrefix = cidrSubnet(hubVnetAddressSpace, 24, 1) // 10.0.1.0/24
var appGatewaySubnetPrefix = cidrSubnet(hubVnetAddressSpace, 24, 2) // 10.0.2.0/24
var managementSubnetPrefix = cidrSubnet(hubVnetAddressSpace, 24, 3) // 10.0.3.0/24
var bastionSubnetPrefix = cidrSubnet(hubVnetAddressSpace, 26, 16) // 10.0.4.0/26
var dnsResolverInboundSubnetPrefix = cidrSubnet(hubVnetAddressSpace, 28, 80) // 10.0.5.0/28

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ============================================================================
// DDOS PROTECTION PLAN (Optional - must be created before VNet if enabled)
// ============================================================================

module ddosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.0' = if (enableDDoSProtection) {
  name: 'deploy-${ddosProtectionPlanName}'
  scope: hubResourceGroup
  params: {
    name: ddosProtectionPlanName
    location: location
    tags: commonTags
  }
}

// ============================================================================
// KEY VAULT
// ============================================================================

module keyVault 'br/public:avm/res/key-vault/vault:0.13.0' = {
  name: 'deploy-${keyVaultName}'
  scope: hubResourceGroup
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    sku: 'standard'
    roleAssignments: !empty(keyVaultAdminPrincipalId)
      ? [
          {
            principalId: keyVaultAdminPrincipalId
            roleDefinitionIdOrName: 'Key Vault Administrator'
          }
        ]
      : []
    diagnosticSettings: [
      {
        name: 'kv-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// NETWORK WATCHER
// ============================================================================

module networkWatcher 'br/public:avm/res/network/network-watcher:0.5.0' = {
  name: 'deploy-${networkWatcherName}'
  scope: hubResourceGroup
  params: {
    name: networkWatcherName
    location: location
    tags: commonTags
  }
}

// ============================================================================
// PRIVATE DNS ZONE
// ============================================================================

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'deploy-privateDnsZone-${uniqueString(privateDnsZoneName)}'
  scope: hubResourceGroup
  params: {
    name: privateDnsZoneName
    tags: commonTags
  }
}

// ============================================================================
// AZURE VIRTUAL NETWORK MANAGER (AVNM)
// ============================================================================

module avnm 'br/public:avm/res/network/network-manager:0.5.0' = {
  name: 'deploy-${avnmName}'
  scope: hubResourceGroup
  params: {
    name: avnmName
    location: location
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
    networkManagerScopes: {
      managementGroups: [
        '/providers/Microsoft.Management/managementGroups/${avnmManagementGroupId}'
      ]
    }
    tags: commonTags
  }
}

// ============================================================================
// IPAM POOL (Optional)
// ============================================================================

module ipamPool './ipam-pool.bicep' = if (enableIpamPool) {
  name: 'deploy-ipam-pool-${ipamPoolName}'
  scope: hubResourceGroup
  params: {
    networkManagerName: avnmName
    ipamPoolName: ipamPoolName
    location: location
    addressPrefixes: [
      ipamPoolAddressSpace
    ]
    poolDescription: ipamPoolDescription
    tags: commonTags
  }
  dependsOn: [
    avnm
  ]
}

// ============================================================================
// HUB VIRTUAL NETWORK
// ============================================================================

module hubVnet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${hubVnetName}'
  scope: hubResourceGroup
  params: {
    name: hubVnetName
    location: location
    addressPrefixes: [
      hubVnetAddressSpace
    ]
    ddosProtectionPlanResourceId: enableDDoSProtection ? ddosProtectionPlan.outputs.resourceId : ''
    subnets: concat(
      [
        {
          name: 'GatewaySubnet'
          addressPrefix: gatewaySubnetPrefix
        }
        {
          name: 'AzureFirewallSubnet'
          addressPrefix: azureFirewallSubnetPrefix
        }
        {
          name: 'AppGatewaySubnet'
          addressPrefix: appGatewaySubnetPrefix
        }
        {
          name: 'Management'
          addressPrefix: managementSubnetPrefix
        }
        {
          name: 'AzureBastionSubnet'
          addressPrefix: bastionSubnetPrefix
        }
      ],
      enableDnsResolver
        ? [
            {
              name: 'DnsResolverInbound'
              addressPrefix: dnsResolverInboundSubnetPrefix
              delegation: 'Microsoft.Network/dnsResolvers'
            }
          ]
        : []
    )
    diagnosticSettings: [
      {
        name: 'vnet-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// IPAM POOL ALLOCATION (Optional - Associates Hub VNet with IPAM Pool)
// ============================================================================

module hubVnetIpamAllocation './ipam-static-cidr.bicep' = if (enableIpamPool) {
  name: 'deploy-ipam-staticcidr-${hubVnetName}'
  scope: hubResourceGroup
  params: {
    networkManagerName: avnmName
    ipamPoolName: ipamPoolName
    staticCidrName: ipamStaticCidrName
    addressPrefixes: [
      hubVnetAddressSpace
    ]
    cidrDescription: 'Hub VNet address space allocation'
  }
  dependsOn: [
    ipamPool
    hubVnet
  ]
}

// Link Private DNS Zone to Hub VNet
// Note: Using the AVM module to add VNet links to the existing Private DNS Zone
// This is a valid pattern as the AVM module supports incremental updates
module privateDnsZoneVnetLink 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'deploy-privateDnsZone-vnetLink'
  scope: hubResourceGroup
  params: {
    name: privateDnsZoneName
    virtualNetworkLinks: [
      {
        name: privateDnsZoneVnetLinkName
        virtualNetworkResourceId: hubVnet.outputs.resourceId
        registrationEnabled: true
      }
    ]
    tags: commonTags
  }
  dependsOn: [
    privateDnsZone
  ]
}

// ============================================================================
// OPTIONAL: PRIVATE DNS RESOLVER
// ============================================================================

module dnsResolver 'br/public:avm/res/network/dns-resolver:0.5.0' = if (enableDnsResolver) {
  name: 'deploy-${dnsResolverName}'
  scope: hubResourceGroup
  params: {
    name: dnsResolverName
    location: location
    virtualNetworkResourceId: hubVnet.outputs.resourceId
    inboundEndpoints: [
      {
        name: dnsResolverInboundEndpointName
        subnetResourceId: '${hubVnet.outputs.resourceId}/subnets/DnsResolverInbound'
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: PUBLIC IP ADDRESSES
// ============================================================================

// Public IP for Application Gateway
module appGatewayPip 'br/public:avm/res/network/public-ip-address:0.9.0' = if (enableAppGatewayWAF) {
  name: 'deploy-${appGatewayPipName}'
  scope: hubResourceGroup
  params: {
    name: appGatewayPipName
    location: location
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagnosticSettings: [
      {
        name: 'pip-agw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// Public IP for VPN Gateway
module vpnGatewayPip 'br/public:avm/res/network/public-ip-address:0.9.0' = if (enableVpnGateway) {
  name: 'deploy-${vpnGatewayPipName}'
  scope: hubResourceGroup
  params: {
    name: vpnGatewayPipName
    location: location
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagnosticSettings: [
      {
        name: 'pip-vpngw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// Public IP for Azure Firewall
module azureFirewallPip 'br/public:avm/res/network/public-ip-address:0.9.0' = if (enableAzureFirewall) {
  name: 'deploy-${azureFirewallPipName}'
  scope: hubResourceGroup
  params: {
    name: azureFirewallPipName
    location: location
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    diagnosticSettings: [
      {
        name: 'pip-afw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: APPLICATION GATEWAY WAF POLICY
// ============================================================================

module appGatewayWafPolicy 'br/public:avm/res/network/application-gateway-web-application-firewall-policy:0.2.0' = if (enableAppGatewayWAF) {
  name: 'deploy-${appGatewayWafPolicyName}'
  scope: hubResourceGroup
  params: {
    name: appGatewayWafPolicyName
    location: location
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
    policySettings: {
      mode: 'Prevention'
      state: 'Enabled'
    }
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: APPLICATION GATEWAY WITH WAF
// ============================================================================

module appGateway 'br/public:avm/res/network/application-gateway:0.7.0' = if (enableAppGatewayWAF) {
  name: 'deploy-${appGatewayName}'
  scope: hubResourceGroup
  params: {
    name: appGatewayName
    location: location
    sku: 'WAF_v2'
    capacity: 2
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${hubVnet.outputs.resourceId}/subnets/AppGatewaySubnet'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: appGatewayPip.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'defaultHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              subscription().subscriptionId,
              resourceGroupName,
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              'appGwPublicFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId(
              subscription().subscriptionId,
              resourceGroupName,
              'Microsoft.Network/applicationGateways/frontendPorts',
              appGatewayName,
              'port_80'
            )
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId(
              subscription().subscriptionId,
              resourceGroupName,
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              'defaultHttpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              subscription().subscriptionId,
              resourceGroupName,
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              'defaultBackendPool'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              subscription().subscriptionId,
              resourceGroupName,
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              'defaultHttpSettings'
            )
          }
        }
      }
    ]
    firewallPolicyResourceId: enableAppGatewayWAF ? appGatewayWafPolicy.outputs.resourceId : ''
    diagnosticSettings: [
      {
        name: 'agw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: AZURE FRONT DOOR (Standard)
// Note: Azure Front Door Standard/Premium uses the cdn/profile AVM module
// (not network/front-door which is for classic Front Door)
// ============================================================================

module frontDoor 'br/public:avm/res/cdn/profile:0.8.0' = if (enableFrontDoor) {
  name: 'deploy-${frontDoorName}'
  scope: hubResourceGroup
  params: {
    name: frontDoorName
    location: 'global'
    sku: 'Standard_AzureFrontDoor'
    originResponseTimeoutSeconds: 60
    afdEndpoints: [
      {
        name: 'default-endpoint'
        enabledState: 'Enabled'
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: VPN GATEWAY WITH P2S CONFIGURATION
// ============================================================================

module vpnGateway 'br/public:avm/res/network/virtual-network-gateway:0.10.0' = if (enableVpnGateway) {
  name: 'deploy-${vpnGatewayName}'
  scope: hubResourceGroup
  params: {
    name: vpnGatewayName
    location: location
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    skuName: 'VpnGw1AZ'
    virtualNetworkResourceId: hubVnet.outputs.resourceId
    clusterSettings: {
      clusterMode: 'activePassiveNoBgp'
    }
    existingPrimaryPublicIPResourceId: vpnGatewayPip.outputs.resourceId
    vpnClientAddressPoolPrefix: vpnClientAddressPoolPrefix
    diagnosticSettings: [
      {
        name: 'vpngw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OPTIONAL: AZURE FIREWALL
// ============================================================================

// Azure Firewall Policy (use AVM)
module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.0' = if (enableAzureFirewall) {
  name: 'deploy-${azureFirewallPolicyName}'
  scope: hubResourceGroup
  params: {
    name: azureFirewallPolicyName
    location: location
    tier: azureFirewallTier
    threatIntelMode: 'Alert'
    tags: commonTags
  }
}

module azureFirewall 'br/public:avm/res/network/azure-firewall:0.9.0' = if (enableAzureFirewall) {
  name: 'deploy-${azureFirewallName}'
  scope: hubResourceGroup
  params: {
    name: azureFirewallName
    location: location
    azureSkuTier: azureFirewallTier
    virtualNetworkResourceId: hubVnet.outputs.resourceId
    publicIPResourceID: azureFirewallPip.outputs.resourceId
    firewallPolicyId: enableAzureFirewall ? firewallPolicy.outputs.resourceId : ''
    diagnosticSettings: [
      {
        name: 'afw-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ]
    tags: commonTags
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output resourceGroupName string = hubResourceGroup.name

@description('The resource ID of the Network Watcher')
output networkWatcherResourceId string = networkWatcher.outputs.resourceId

@description('The name of the Private DNS Zone')
output privateDnsZoneName string = privateDnsZone.outputs.name

@description('The resource ID of the Private DNS Zone')
output privateDnsZoneResourceId string = privateDnsZone.outputs.resourceId

@description('The resource ID of the Azure Virtual Network Manager')
output avnmResourceId string = avnm.outputs.resourceId

@description('The name of the Hub Virtual Network')
output hubVnetName string = hubVnet.outputs.name

@description('The resource ID of the Hub Virtual Network')
output hubVnetResourceId string = hubVnet.outputs.resourceId

@description('The subnet resource IDs of the Hub Virtual Network')
output hubVnetSubnetResourceIds array = hubVnet.outputs.subnetResourceIds

@description('The resource ID of the Application Gateway (if enabled)')
output appGatewayResourceId string = enableAppGatewayWAF ? appGateway.outputs.resourceId : ''

@description('The resource ID of the Azure Front Door (if enabled)')
output frontDoorResourceId string = enableFrontDoor ? frontDoor.outputs.resourceId : ''

@description('The resource ID of the VPN Gateway (if enabled)')
output vpnGatewayResourceId string = enableVpnGateway ? vpnGateway.outputs.resourceId : ''

@description('The resource ID of the Azure Firewall (if enabled)')
output azureFirewallResourceId string = enableAzureFirewall ? azureFirewall.outputs.resourceId : ''

@description('The private IP address of the Azure Firewall (if enabled)')
output azureFirewallPrivateIp string = enableAzureFirewall ? azureFirewall.outputs.privateIp : ''

@description('The resource ID of the DDoS Protection Plan (if enabled)')
output ddosProtectionPlanResourceId string = enableDDoSProtection ? ddosProtectionPlan.outputs.resourceId : ''

@description('The name of the Key Vault')
output keyVaultName string = keyVault.outputs.name

@description('The resource ID of the Key Vault')
output keyVaultResourceId string = keyVault.outputs.resourceId

@description('The URI of the Key Vault')
output keyVaultUri string = keyVault.outputs.uri

@description('The resource ID of the Private DNS Resolver (if enabled)')
output dnsResolverResourceId string = enableDnsResolver ? dnsResolver.outputs.resourceId : ''

@description('The name of the Private DNS Resolver (if enabled)')
output dnsResolverName string = enableDnsResolver ? dnsResolver.outputs.name : ''

@description('The resource ID of the IPAM Pool (if enabled)')
output ipamPoolResourceId string = enableIpamPool ? ipamPool.outputs.resourceId : ''

@description('The name of the IPAM Pool (if enabled)')
output ipamPoolName string = enableIpamPool ? ipamPool.outputs.name : ''

@description('The name of the Network Watcher')
output networkWatcherName string = networkWatcher.outputs.name

@description('The name of the Azure Virtual Network Manager')
output avnmName string = avnm.outputs.name

@description('The name of the Application Gateway (if enabled)')
output appGatewayName string = enableAppGatewayWAF ? appGateway.outputs.name : ''

@description('The name of the Azure Front Door (if enabled)')
output frontDoorName string = enableFrontDoor ? frontDoor.outputs.name : ''

@description('The name of the VPN Gateway (if enabled)')
output vpnGatewayName string = enableVpnGateway ? vpnGateway.outputs.name : ''

@description('The name of the Azure Firewall (if enabled)')
output azureFirewallName string = enableAzureFirewall ? azureFirewall.outputs.name : ''

@description('The name of the DDoS Protection Plan (if enabled)')
output ddosProtectionPlanName string = enableDDoSProtection ? ddosProtectionPlan.outputs.name : ''
