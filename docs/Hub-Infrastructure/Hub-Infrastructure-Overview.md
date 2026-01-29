# Hub Infrastructure Overview

## Introduction

The hub infrastructure provides the central networking foundation for your Azure environment. It establishes the core connectivity, security, and management services that support all workloads in your organization. The hub is deployed using Azure Verified Modules (AVM) and managed through Azure Deployment Stacks.

## Architecture

```
Hub Subscription
└── Resource Group: rg-hub-<env>-<loc>-<instance>
    ├── Network Watcher
    ├── Private DNS Zone
    ├── Azure Virtual Network Manager (AVNM)
    ├── Hub Virtual Network
    │   ├── GatewaySubnet
    │   ├── AzureFirewallSubnet
    │   ├── AppGatewaySubnet
    │   ├── Management
    │   ├── AzureBastionSubnet
    │   └── DnsResolverInbound (optional)
    ├── Key Vault
    ├── IPAM Pool (optional)
    └── Optional Components:
        ├── Application Gateway + WAF
        ├── Azure Front Door
        ├── VPN Gateway
        ├── Azure Firewall
        ├── DDoS Protection Plan
        └── Private DNS Resolver
```

## Core Components

### Resource Group

The hub infrastructure is deployed into a dedicated resource group following the naming convention:
- **Pattern**: `rg-<workloadAlias>-<env>-<loc>-<instance>`
- **Example**: `rg-hub-live-cac-001`

### Network Watcher

Network Watcher provides network monitoring and diagnostic capabilities for Azure virtual networks.

**Features:**
- Network topology visualization
- Connection monitoring
- Packet capture
- IP flow verification
- Next hop analysis
- VPN diagnostics

### Private DNS Zone

A private DNS zone provides internal DNS resolution for your organization's private resources.

**Configuration:**
- **Zone Name**: Configurable (e.g., `internal.organization.com`)
- **Auto-registration**: Enabled for VMs in linked virtual networks
- **Integration**: Automatically linked to the hub virtual network

**Use Cases:**
- Internal service discovery
- Private endpoint resolution
- Custom domain names for internal resources

### Azure Virtual Network Manager (AVNM)

AVNM provides centralized network management and configuration across your Azure environment.

**Capabilities:**
- **Connectivity Management**: Hub-and-spoke topology configuration
- **Security Admin**: Centralized security rule management
- **IPAM**: Centralized IP address management (optional)

**Scope:**
- Configured at management group level
- Manages networks across multiple subscriptions
- Default scope: `mg-connectivity` management group

### Hub Virtual Network

The hub virtual network is the central network for connectivity and shared services.

**Address Space:**
- Configurable (default: `10.0.0.0/16`)
- Subnets automatically calculated from address space

**Standard Subnets:**

| Subnet Name | Purpose | Prefix Calculation |
|-------------|---------|-------------------|
| GatewaySubnet | VPN/ExpressRoute gateways | `/24` from address space |
| AzureFirewallSubnet | Azure Firewall (if enabled) | `/24` offset +1 |
| AppGatewaySubnet | Application Gateway (if enabled) | `/24` offset +2 |
| Management | Management VMs and services | `/24` offset +3 |
| AzureBastionSubnet | Azure Bastion (if deployed) | `/26` offset +16 |

**Optional Subnets:**
- **DnsResolverInbound**: For Private DNS Resolver (if enabled)

### Key Vault

A Key Vault is deployed for secure storage of secrets, keys, and certificates used by hub infrastructure components.

**Configuration:**
- **RBAC Authorization**: Enabled
- **Soft Delete**: Enabled (90-day retention)
- **Purge Protection**: Enabled
- **SKU**: Standard

## Optional Components

### Application Gateway with WAF

Provides Layer 7 load balancing and web application firewall protection.

**Features:**
- SSL/TLS termination
- URL-based routing
- Web Application Firewall (WAF) with OWASP rules
- Health probes and automatic failover
- Standard SKU with WAF_v2

**Configuration:**
- Deployed in dedicated `AppGatewaySubnet`
- Public IP address for internet-facing traffic
- Default backend pool (configurable post-deployment)

### Azure Front Door (Standard)

Global content delivery network (CDN) and application acceleration service.

**Features:**
- Global load balancing
- SSL/TLS termination
- DDoS protection
- Web Application Firewall integration
- Custom domain support

### VPN Gateway

Provides point-to-site (P2S) VPN connectivity for remote users.

**Configuration:**
- **SKU**: VpnGw1AZ (Zone-redundant)
- **Type**: Route-based VPN
- **Client Address Pool**: Configurable (default: `172.16.0.0/24`)
- **Deployment**: Active-passive cluster mode

**Use Cases:**
- Remote user access
- Branch office connectivity
- Secure access to private resources

### Azure Firewall

Managed, cloud-native network security service.

**Features:**
- **SKU Options**: Standard or Premium
- **Threat Intelligence**: Built-in threat intelligence feeds
- **Application Rules**: FQDN-based filtering
- **Network Rules**: IP address and port filtering
- **NAT Rules**: Destination NAT (DNAT)

**Configuration:**
- Deployed in dedicated `AzureFirewallSubnet`
- Public IP address for outbound internet access
- Firewall Policy for centralized rule management

### DDoS Protection Plan

Provides enhanced DDoS protection for Azure resources.

**Features:**
- Always-on traffic monitoring
- Automatic attack mitigation
- Attack analytics and reporting
- Integration with Azure Firewall and Application Gateway

**Note**: Must be enabled before virtual network creation if required.

### Private DNS Resolver

Provides DNS resolution between on-premises and Azure networks.

**Features:**
- Inbound endpoints for on-premises DNS queries
- Outbound endpoints for Azure-to-on-premises queries
- Conditional forwarding rules

**Configuration:**
- Requires dedicated `DnsResolverInbound` subnet
- Integrated with Private DNS Zones

### IPAM Pool

Centralized IP address management for hub and spoke networks.

**Features:**
- Centralized IP address space management
- Automatic allocation tracking
- Conflict prevention
- Integration with Azure Virtual Network Manager

**Configuration:**
- **Address Space**: Configurable (default: `10.0.0.0/8`)
- **Scope**: Management group level
- **Allocation**: Hub VNet automatically allocated from pool

## Naming Convention

Resources follow a consistent naming convention:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-<workloadAlias>-<env>-<loc>-<instance>` | `rg-hub-live-cac-001` |
| Virtual Network | `vnet-<workloadAlias>-<env>-<loc>-<instance>` | `vnet-hub-live-cac-001` |
| Network Watcher | `NetworkWatcher_<loc>` | `NetworkWatcher_cac` |
| AVNM | `avnm-<workloadAlias>-<env>-<loc>-<instance>` | `avnm-hub-live-cac-001` |
| Application Gateway | `agw-<workloadAlias>-<env>-<loc>-<instance>` | `agw-hub-live-cac-001` |
| Azure Firewall | `afw-<workloadAlias>-<env>-<loc>-<instance>` | `afw-hub-live-cac-001` |
| VPN Gateway | `vpngw-<workloadAlias>-<env>-<loc>-<instance>` | `vpngw-hub-live-cac-001` |
| Key Vault | `kv-<workloadAlias>-<env>-<loc>-<instance>` | `kv-hub-live-cac-001` |
| IPAM Pool | `ipam-<workloadAlias>-<env>-<loc>-<instance>` | `ipam-hub-live-cac-001` |

### Naming Components

- **workloadAlias**: The workload alias for naming (e.g., `hub`, `mngmnt`)
- **env**: Environment identifier (e.g., `live`, `nonprod`, `dev`)
- **loc**: Location code (e.g., `cac` for Canada Central)
- **instance**: Instance number (e.g., `001`)

## Integration Points

### Monitoring Infrastructure

All hub resources send diagnostic logs and metrics to the centralized Log Analytics workspace:

- Virtual Network flow logs
- Application Gateway access logs
- Azure Firewall logs
- VPN Gateway connection logs
- Key Vault audit logs
- Public IP address metrics

### Management Group Hierarchy

The hub infrastructure integrates with the management group hierarchy:

- **AVNM Scope**: Configured at management group level (default: `mg-connectivity`)
- **IPAM Pool**: Manages IP addresses across management group scope
- **Policy Integration**: Can apply network policies at management group level

### Spoke Networks

The hub is designed to connect with spoke virtual networks:

- **Peering**: Spoke networks peer with hub VNet
- **Routing**: Hub provides transit routing between spokes
- **Security**: Azure Firewall provides centralized security
- **DNS**: Private DNS Zone shared across hub and spokes

## Default Configuration

The default deployment creates:

| Parameter | Default Value |
|-----------|---------------|
| Workload Alias | `hub` |
| Environment | `live` |
| Location | `canadacentral` |
| Location Code | `cac` |
| Instance Number | `001` |
| Hub VNet Address Space | `10.0.0.0/16` |
| Private DNS Zone | `internal.organization.com` |
| AVNM Management Group | `mg-connectivity` |
| Managed By | `Bicep` |

**Optional Components**: All disabled by default

## Azure Verified Modules

The hub infrastructure uses Azure Verified Modules (AVM) for all resources:

| Resource | AVM Module | Version |
|----------|------------|---------|
| Virtual Network | `br/public:avm/res/network/virtual-network` | `0.7.0` |
| Network Watcher | `br/public:avm/res/network/network-watcher` | `0.5.0` |
| Private DNS Zone | `br/public:avm/res/network/private-dns-zone` | `0.8.0` |
| Network Manager | `br/public:avm/res/network/network-manager` | `0.5.0` |
| Application Gateway | `br/public:avm/res/network/application-gateway` | `0.7.0` |
| Azure Firewall | `br/public:avm/res/network/azure-firewall` | `0.9.0` |
| VPN Gateway | `br/public:avm/res/network/virtual-network-gateway` | `0.10.0` |
| Key Vault | `br/public:avm/res/key-vault/vault` | `0.13.0` |
| Public IP | `br/public:avm/res/network/public-ip-address` | `0.9.0` |
| DDoS Protection | `br/public:avm/res/network/ddos-protection-plan` | `0.3.0` |
| DNS Resolver | `br/public:avm/res/network/dns-resolver` | `0.5.0` |

These modules provide:
- Best-practice configuration
- Consistent deployment patterns
- Microsoft-validated implementation

## Deployment Stack Protection

The infrastructure is deployed as a Deployment Stack, providing:

- **Deny Settings**: Prevent unauthorized modifications
- **Managed Resources**: Track all resources in the stack
- **Unmanage Actions**: Control what happens when resources are removed from the template

**Default Settings:**
- **Deny Mode**: `denyWriteAndDelete` (recommended for production)
- **Action on Unmanage**: `detachAll` (preserves resources if removed from template)

## Next Steps

- [Deploying Hub Infrastructure](Deploying-Hub-Infrastructure.md) - Learn how to deploy
- [Managing Hub Infrastructure](Managing-Hub-Infrastructure.md) - Ongoing management
