# Spoke Infrastructure

This section provides comprehensive documentation for deploying and managing spoke networking infrastructure in Azure.

## Overview

Spoke infrastructure provides dedicated networking environments for workloads and development teams. Each spoke is deployed as a separate virtual network (VNet) that automatically connects to the hub infrastructure via Azure Virtual Network Manager (AVNM). This architecture enables isolation between workloads while maintaining centralized connectivity and security management.

## Documentation Structure

- [Spoke Infrastructure Overview](Spoke-Infrastructure/Spoke-Infrastructure-Overview.md) - Learn about the architecture and components
- [Deploying Spoke Infrastructure](Spoke-Infrastructure/Deploying-Spoke-Infrastructure.md) - Step-by-step deployment guide

## Quick Links

- **Bicep Template**: `code/bicep/spoke/spoke-networking.bicep`
- **Parameters File**: `code/bicep/spoke/spoke-networking.bicepparam`
- **Pipeline**: `code/pipelines/spoke-networking-pipeline.yaml`

## Key Concepts

- **Two-Stage Deployment**: Subscription creation followed by spoke networking deployment
- **Spoke Virtual Network**: Dedicated network for workload isolation
- **AVNM Connectivity**: Automatic hub-spoke connectivity via Azure Virtual Network Manager
- **Private DNS Integration**: Links to hub Private DNS Zone for internal resolution
- **IPAM Integration**: Optional centralized IP address management
- **Deployment Stack**: Protection against accidental deletion and modification
- **Dev Team Handoff**: Spoke resources can be managed by dev teams while VNet remains protected

## Deployment Process

1. **Stage 1**: Create spoke subscription using `sub-vending-pipeline.yaml`
2. **Stage 2**: Deploy spoke networking using `spoke-networking-pipeline.yaml`

## Integration with Hub

Spoke infrastructure requires the following from hub infrastructure:

| Dependency | Description |
|------------|-------------|
| Private DNS Zone | For internal DNS resolution |
| AVNM | For automatic connectivity |
| Log Analytics | For diagnostic settings |
| IPAM Pool (optional) | For centralized IP management |
