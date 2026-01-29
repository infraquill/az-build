# Hub Infrastructure

This section provides comprehensive documentation for deploying and managing the hub networking infrastructure in Azure.

## Overview

The hub infrastructure provides the central networking foundation for your Azure environment, including virtual networks, network management services, and optional security and connectivity components. It uses Azure Verified Modules (AVM) and is managed through Azure Deployment Stacks.

## Documentation Structure

- [Hub Infrastructure Overview](Hub-Infrastructure/Hub-Infrastructure-Overview.md) - Learn about the architecture and components
- [Deploying Hub Infrastructure](Hub-Infrastructure/Deploying-Hub-Infrastructure.md) - Step-by-step deployment guide
- [Managing Hub Infrastructure](Hub-Infrastructure/Managing-Hub-Infrastructure.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/hub/hub.bicep`
- **Parameters File**: `code/bicep/hub/hub.bicepparam`
- **Pipeline**: `code/pipelines/hub-pipeline.yaml`

## Key Concepts

- **Hub Virtual Network**: Central network for connectivity and shared services
- **Azure Virtual Network Manager (AVNM)**: Centralized network management and configuration
- **Private DNS Zone**: Internal DNS resolution for private resources
- **Network Watcher**: Network monitoring and diagnostic capabilities
- **Deployment Stack**: Azure deployment mechanism providing protection against accidental deletion and modification
- **IPAM Pool**: Centralized IP address management for hub and spoke networks
- **Optional Components**: Application Gateway, Azure Firewall, VPN Gateway, DDoS Protection, and more
