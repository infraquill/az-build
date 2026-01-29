# CloudOps Overview

## Introduction

CloudOps is the first workload deployed in your Azure environment, serving as the central infrastructure deployment and management platform. It uses **Azure Managed DevOps Pools** (`Microsoft.DevOpsInfrastructure/pools`) deployed in a dedicated spoke virtual network, providing Azure DevOps agents that can deploy and manage infrastructure across all spoke networks.

## Why Managed DevOps Pools?

Managed DevOps Pools (MDP) is a fully managed Azure service that provides significant advantages over traditional VMSS-based self-hosted agents:

| Feature | Managed DevOps Pools | Traditional VMSS |
|---------|----------------------|------------------|
| Agent Installation | Automatic | Custom scripts/extensions |
| Agent Updates | Automatic | Manual/custom |
| Scale-to-Zero | Native support | Manual implementation |
| PAT Token Management | Not required | Required |
| Image Management | Pre-configured images | Custom image maintenance |
| Lifecycle Management | Fully managed | Manual |

## Architecture

```
Hub Subscription (Connectivity)
└── Hub Resource Group
    ├── Azure Virtual Network Manager (AVNM)
    ├── Hub Virtual Network
    └── Private DNS Zone
        │
        │  AVNM Connectivity (automatic)
        │
        ▼
CloudOps Subscription (Workload)
├── Deployment Stack: stack-devcenter-{env}-{loc}-{instance}
│   └── Resource Group: rg-devcenter-{env}-{loc}-{instance}
│       ├── DevCenter: dc-devcenter-{env}-{loc}-{instance}
│       └── Network Connection: nc-devcenter-{env}-{loc}-{instance}
│
├── Deployment Stack: stack-cloudops-{env}-{loc}-{instance}
│   └── Resource Group: rg-cloudops-{env}-{loc}-{instance}
│       ├── DevCenter Project: dcp-cloudops-{env}-{loc}-{instance}
│       └── Managed DevOps Pool: mdp-cloudops-{env}-{loc}-{instance}
│           ├── Automatic Agent Provisioning
│           ├── Native Scale-to-Zero
│           └── Pre-configured Azure DevOps Images
│
└── Spoke Networking (from Stage 2)
    └── Resource Group: rg-cloudops-{env}-{loc}-{instance}
        └── CloudOps VNet: vnet-cloudops-{env}-{loc}-{instance}
            ├── Pool Subnet
            └── Private DNS Zone Link → Hub Private DNS Zone
```

## Four-Stage Deployment Process

CloudOps provisioning uses a four-stage deployment approach:

### Stage 1: Subscription Creation

Use the existing `sub-vending.bicep` to create the CloudOps subscription:

- Creates subscription via Azure EA/MCA billing
- Assigns subscription to management group (e.g., `mg-corp-prod`)
- `virtualNetworkEnabled: false` - VNet created separately in Stage 2
- Tags subscription with ownership and management metadata

### Stage 2: Spoke Networking

Use `spoke-networking.bicep` to deploy networking infrastructure:

- Creates resource group and CloudOps spoke VNet
- Configures pool subnet
- Links to hub Private DNS Zone
- Optionally allocates address space via IPAM
- AVNM automatically connects spoke to hub

### Stage 3: DevCenter Infrastructure

Use `devcenter.bicep` to deploy DevCenter (one-time per organization):

- Creates DevCenter resource
- Creates Network Connection for private networking
- DevCenter can be shared across multiple pools

### Stage 4: CloudOps Workload

Use `cloudops.bicep` to deploy the workload:

- Creates workload resource group
- Creates DevCenter Project
- Deploys Managed DevOps Pool with native scale-to-zero
- Uses pre-configured Azure DevOps agent images

## Core Components

### DevCenter

DevCenter is the organizational container for Managed DevOps Pools:

- **Pattern**: `dc-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `dc-devcenter-live-cac-001`
- Typically deployed once per organization
- Shared across multiple pools

### Network Connection

Enables private networking for Managed DevOps Pools:

- **Pattern**: `nc-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `nc-devcenter-live-cac-001`
- Attaches to CloudOps spoke subnet
- Azure AD join (no on-premises domain required)

### DevCenter Project

Organizational container for pools within CloudOps:

- **Pattern**: `dcp-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `dcp-cloudops-live-cac-001`
- Links to the DevCenter

### Managed DevOps Pool

Azure-managed DevOps agents with native scale-to-zero:

- **Pattern**: `mdp-{workloadAlias}-{environment}-{locationCode}-{instanceNumber}`
- **Example**: `mdp-cloudops-live-cac-001`
- Automatic agent provisioning and updates
- Native scale-to-zero support
- Pre-configured Azure DevOps images

## Connectivity Model

### AVNM Integration

Azure Virtual Network Manager provides automatic connectivity:

1. Hub AVNM is scoped to the connectivity management group
2. CloudOps spoke VNet is automatically included in connectivity configurations
3. No manual VNet peering required
4. Centralized connectivity management

### Line of Sight to Spokes

The CloudOps pool agents can reach all spoke VNets because:

- All spokes under the connectivity management group are connected via AVNM
- Traffic flows through the hub VNet
- New spokes are automatically connected as they are provisioned

### Azure DevOps Integration

Managed DevOps Pools integrate natively with Azure DevOps:

- Automatic agent pool creation in Azure DevOps
- No PAT tokens required for agent registration
- Native Azure DevOps organization linking
- Support for organization-wide or project-scoped pools

## Pool Configuration Options

### Agent Images

| Image | OS | Use Case |
|-------|-----|----------|
| `ubuntu-22.04/latest` | Linux | Recommended for most scenarios |
| `ubuntu-24.04/latest` | Linux | Latest Ubuntu LTS |
| `windows-2022/latest` | Windows | .NET Framework, Windows-specific builds |
| `windows-2019/latest` | Windows | Legacy Windows support |

### VM Sizes

| SKU | vCPU | RAM | Use Case |
|-----|------|-----|----------|
| Standard_D2s_v5 | 2 | 8 GB | Light workloads |
| Standard_D4s_v5 | 4 | 16 GB | Standard workloads (recommended) |
| Standard_D8s_v5 | 8 | 32 GB | Heavy build workloads |

### Scaling Configuration

- **Minimum Concurrency**: 1 (pools always require at least 1 for configuration)
- **Recommended**: 2-4 (for availability and workload distribution)
- **Maximum**: 10,000 (very large organizations)

### Scale-to-Zero (Native Support)

Managed DevOps Pools have native scale-to-zero support:

- **Enabled by default**: `enableScaleToZero: true`
- **Prediction Preference**: `MostCostEffective` for aggressive cost optimization
- **How it works**:
  - Pool monitors Azure DevOps job queue
  - Scales down to 0 agents when queue is empty
  - Automatically provisions agents when jobs are queued
  - Typical startup time: 2-5 minutes

**Benefits**:
- Zero compute costs during idle periods
- No manual intervention required
- Automatic scaling based on demand
- Perfect for variable workloads

## Deployment Stack Protection

CloudOps is deployed as an Azure Deployment Stack:

- **Deny Settings**: `denyWriteAndDelete` prevents unauthorized modifications
- **Action on Unmanage**: `detachAll` preserves resources if stack is deleted
- Changes must go through pipeline updates

## Resource Naming Convention

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| DevCenter RG | `rg-{workloadAlias}-{env}-{loc}-{instance}` | `rg-devcenter-live-cac-001` |
| DevCenter | `dc-{workloadAlias}-{env}-{loc}-{instance}` | `dc-devcenter-live-cac-001` |
| Network Connection | `nc-{workloadAlias}-{env}-{loc}-{instance}` | `nc-devcenter-live-cac-001` |
| CloudOps RG | `rg-{workloadAlias}-{env}-{loc}-{instance}` | `rg-cloudops-live-cac-001` |
| DevCenter Project | `dcp-{workloadAlias}-{env}-{loc}-{instance}` | `dcp-cloudops-live-cac-001` |
| Managed Pool | `mdp-{workloadAlias}-{env}-{loc}-{instance}` | `mdp-cloudops-live-cac-001` |
| Deployment Stack | `stack-{workloadAlias}-{env}-{loc}-{instance}` | `stack-cloudops-live-cac-001` |

## Security Considerations

### Network Security

- Private connectivity via Network Connection
- Agents deployed in CloudOps spoke subnet
- NSGs can be applied to pool subnet
- Traffic inspection via Azure Firewall (if deployed in hub)

### Identity Security

- Azure-managed identity for pool agents
- No PAT tokens required
- RBAC roles assigned per subscription/resource scope

### Data Security

- Pre-configured secure images
- Automatic security updates
- Ephemeral agents (stateless)

## Prerequisites

### Azure DevOps Permissions

The deployment principal must have `Administrator` permissions in Azure DevOps to allow Managed DevOps Pools to create agent pools. See [Verify Azure DevOps Permissions](https://learn.microsoft.com/en-us/azure/devops/managed-devops-pools/prerequisites?view=azure-devops&tabs=azure-portal#verify-azure-devops-permissions).

### Resource Provider Registration

Register `Microsoft.DevOpsInfrastructure` provider in the subscription:

```bash
az provider register --namespace Microsoft.DevOpsInfrastructure
```

## Dependencies

| Dependency | Source | Required For |
|------------|--------|--------------|
| CloudOps Subscription | Stage 1 (sub-vending) | Deployment target |
| CloudOps Spoke VNet | Stage 2 (spoke-networking) | Pool networking |
| Pool Subnet | Stage 2 (spoke-networking) | Agent connectivity |
| DevCenter | Stage 3 (devcenter) | Pool organization |
| Network Connection | Stage 3 (devcenter) | Private networking |
| Hub AVNM | Hub infrastructure | Spoke connectivity |
| Private DNS Zone | Hub infrastructure | DNS resolution |
