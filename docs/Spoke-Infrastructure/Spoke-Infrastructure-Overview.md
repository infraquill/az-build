# Spoke Infrastructure Overview

## Introduction

Spoke infrastructure provides dedicated networking environments for workloads and development teams. Each spoke is deployed as a separate virtual network (VNet) that automatically connects to the hub infrastructure via Azure Virtual Network Manager (AVNM). This architecture enables isolation between workloads while maintaining centralized connectivity and security management.

## Architecture

```
Hub Subscription (Connectivity)
└── Hub Resource Group
    ├── Azure Virtual Network Manager (AVNM)
    ├── Hub Virtual Network
    ├── Private DNS Zone
    └── IPAM Pool (optional)
        │
        │  AVNM Connectivity (automatic)
        │
        ▼
Spoke Subscription (Workload)
└── Deployment Stack: stack-{workloadAlias}-{env}-{loc}-{instance}
    └── Resource Group: rg-{workloadAlias}-{env}-{loc}-{instance}
        └── Spoke Virtual Network: vnet-{workloadAlias}-{env}-{loc}-{instance}
            ├── Workload Subnets (configurable)
            ├── Private DNS Zone Link → Hub Private DNS Zone
            └── IPAM Static CIDR Allocation (optional)
```

## Two-Stage Deployment Process

Spoke provisioning uses a two-stage deployment approach:

### Stage 1: Subscription Creation

Use the existing `sub-vending.bicep` to create the spoke subscription:

- Creates subscription via Azure EA/MCA billing
- Assigns subscription to management group (e.g., `mg-corp-prod`, `mg-corp-non-prod`)
- `virtualNetworkEnabled: false` - VNet created separately in Stage 2
- Tags subscription with ownership and management metadata

### Stage 2: Spoke Networking

Use `spoke-networking.bicep` to deploy networking infrastructure:

- Creates resource group and spoke VNet
- Configures workload subnets
- Links to hub Private DNS Zone
- Optionally allocates address space via IPAM
- AVNM automatically connects spoke to hub

## Core Components

### Resource Group

The spoke infrastructure is deployed into a dedicated resource group:

- **Pattern**: `rg-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `rg-webapp-dev-cac-001`

### Spoke Virtual Network

The spoke VNet provides network isolation for workloads:

- **Pattern**: `vnet-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `vnet-webapp-dev-cac-001`
- Address space configurable (e.g., `10.1.0.0/16`)
- Diagnostic settings to Log Analytics Workspace

### Workload Subnets

Subnets are configurable based on workload requirements:

**Default Configuration** (if no custom subnets specified):
- `workload` - First /24 of the VNet address space

**Custom Configuration** (example):
```
- web: 10.1.0.0/24
- app: 10.1.1.0/24
- data: 10.1.2.0/24
```

### Private DNS Zone Link

Links the spoke VNet to the hub's Private DNS Zone:

- Enables internal DNS resolution (e.g., `*.internal.organization.com`)
- Auto-registration enabled for VM DNS records
- Cross-subscription linking to hub Private DNS Zone

## AVNM Connectivity

Azure Virtual Network Manager (AVNM) provides automatic hub-spoke connectivity:

### How It Works

1. Hub AVNM is scoped to the connectivity management group (e.g., `mg-connectivity`)
2. AVNM has `Connectivity` access enabled
3. When a spoke VNet is created in a subscription under the scoped management group:
   - AVNM can automatically include it in connectivity configurations
   - No manual VNet peering required
   - Centralized connectivity management

### Important Notes

- AVNM connectivity configuration must be created and committed in the hub
- Spoke VNets are automatically detected when in scope
- Routing and security policies are managed centrally

## Optional: IPAM Integration

If the hub has IPAM (IP Address Management) enabled, spokes can use centralized address management:

### Benefits

- Prevents IP address conflicts
- Centralized tracking of address allocations
- Audit trail of network assignments

### Configuration

When `enableIpamAllocation: true`:
- Requires `hubAvnmName` and `hubIpamPoolName`
- Creates a Static CIDR allocation in the hub IPAM Pool
- Records the spoke VNet address space

## Deployment Stack Protection

Spoke networking is deployed as an Azure Deployment Stack:

### Protection Features

- **Deny Settings**: `denyWriteAndDelete` prevents modification of VNet
- **Action on Unmanage**: `detachAll` preserves resources if stack is deleted
- Dev teams cannot accidentally modify network infrastructure

### What Dev Teams Can Do

- Create resources within the spoke VNet (VMs, App Services, etc.)
- Deploy applications and workloads
- Manage resources in subnets

### What Dev Teams Cannot Do

- Modify VNet address space
- Delete or modify subnets
- Change Private DNS Zone links
- Remove the spoke VNet

## Integration Points

### Hub Infrastructure Dependencies

The spoke requires these outputs from hub infrastructure:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `hubPrivateDnsZoneName` | Private DNS Zone name | `internal.organization.com` |
| `hubPrivateDnsZoneResourceId` | Resource ID of Private DNS Zone | `/subscriptions/.../privateDnsZones/...` |
| `hubResourceGroupName` | Hub resource group | `rg-hub-live-cac-001` |
| `hubSubscriptionId` | Hub subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

### Optional IPAM Dependencies (if enabled)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `hubAvnmName` | Hub AVNM name | `avnm-hub-live-cac-001` |
| `hubIpamPoolName` | Hub IPAM Pool name | `ipam-hub-live-cac-001` |

### Monitoring Integration

- All diagnostic settings send to the common Log Analytics Workspace
- `logAnalyticsWorkspaceResourceId` from monitoring infrastructure

## Naming Conventions

All resources follow the standard naming pattern:

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-{workloadAlias}-{env}-{loc}-{instance}` | `rg-webapp-dev-cac-001` |
| Virtual Network | `vnet-{workloadAlias}-{env}-{loc}-{instance}` | `vnet-webapp-dev-cac-001` |
| Deployment Stack | `stack-{workloadAlias}-{env}-{loc}-{instance}` | `stack-webapp-dev-cac-001` |

## Azure Verified Modules

Spoke infrastructure uses Azure Verified Modules (AVM):

| Resource | AVM Module |
|----------|------------|
| Virtual Network | `br/public:avm/res/network/virtual-network:0.7.0` |
| Private DNS Zone | `br/public:avm/res/network/private-dns-zone:0.8.0` |

## Next Steps

- [Deploying Spoke Infrastructure](Deploying-Spoke-Infrastructure.md) - Step-by-step deployment guide
