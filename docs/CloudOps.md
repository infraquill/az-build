# CloudOps Infrastructure

This section provides comprehensive documentation for deploying and managing the CloudOps workload infrastructure in Azure using **Managed DevOps Pools**.

## Overview

CloudOps is the first workload in your Azure environment, using Azure **Managed DevOps Pools** (`Microsoft.DevOpsInfrastructure/pools`) deployed in a dedicated spoke virtual network. Managed DevOps Pools provide Azure DevOps agents with native scale-to-zero support, automatic agent management, and connectivity to all spoke networks via Azure Virtual Network Manager (AVNM), enabling infrastructure deployment and management across your entire Azure environment.

## Documentation Structure

- [CloudOps Overview](CloudOps/CloudOps-Overview.md) - Learn about the architecture and components
- [Deploying CloudOps](CloudOps/Deploying-CloudOps.md) - Step-by-step deployment guide
- [Managing CloudOps](CloudOps/Managing-CloudOps.md) - Ongoing management and operations

## Quick Links

- **DevCenter Bicep Template**: `code/bicep/cloudops/devcenter.bicep`
- **DevCenter Parameters**: `code/bicep/cloudops/devcenter.bicepparam`
- **CloudOps Bicep Template**: `code/bicep/cloudops/cloudops.bicep`
- **CloudOps Parameters**: `code/bicep/cloudops/cloudops.bicepparam`
- **DevCenter Pipeline**: `code/pipelines/cloudops-devcenter-pipeline.yaml`
- **CloudOps Pipeline**: `code/pipelines/cloudops-pipeline.yaml`

## Key Concepts

- **Four-Stage Deployment**: Subscription creation, spoke networking, DevCenter, then CloudOps workload
- **Managed DevOps Pools**: Azure-managed agents with automatic provisioning and updates
- **Native Scale-to-Zero**: Built-in cost optimization - pay only when jobs are running
- **Private Connectivity**: Pool agents use private networking via Network Connection
- **AVNM Connectivity**: Automatic hub-spoke connectivity via Azure Virtual Network Manager
- **Pre-configured Images**: Use well-known Azure DevOps images (Ubuntu, Windows)
- **Deployment Stack**: Protection against accidental deletion and modification

## Why Managed DevOps Pools?

| Feature | Managed DevOps Pools | Traditional VMSS |
|---------|----------------------|------------------|
| Agent Installation | Automatic | Custom scripts required |
| Agent Updates | Automatic | Manual/custom |
| Scale-to-Zero | Native support | Manual implementation |
| PAT Token Management | Not required | Required |
| Image Management | Pre-configured images | Custom image maintenance |

## Deployment Process

1. **Stage 1**: Create CloudOps subscription using `sub-vending-pipeline.yaml`
2. **Stage 2**: Deploy CloudOps spoke networking using `spoke-networking-pipeline.yaml`
3. **Stage 3**: Deploy DevCenter infrastructure using `cloudops-devcenter-pipeline.yaml`
4. **Stage 4**: Deploy CloudOps workload (Managed DevOps Pool) using `cloudops-pipeline.yaml`

## Integration with Hub

CloudOps infrastructure requires the following from hub infrastructure:

| Dependency | Description |
|------------|-------------|
| AVNM | For automatic connectivity to hub and all spokes |
| Log Analytics | For diagnostic settings and monitoring |
| Private DNS Zone | For internal DNS resolution |

## Connectivity Model

The CloudOps Managed DevOps Pool agents have line of sight to:

- **Hub VNet**: Via AVNM connectivity
- **All Spoke VNets**: Via AVNM (automatic as new spokes are added)
- **Azure DevOps**: Native integration (no PAT tokens required)

This enables the CloudOps agents to deploy and manage infrastructure across all current and future spoke networks without requiring additional network configuration.
