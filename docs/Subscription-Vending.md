# Subscription Vending

This section provides comprehensive documentation for creating and managing Azure subscriptions using the subscription vending process.

## Overview

Subscription vending automates the creation of Azure subscriptions with consistent naming conventions, proper management group placement, and standardized tagging. It uses direct Bicep resource definitions and is deployed at the tenant scope.

> **Note**: This implementation uses direct Azure resource definitions rather than the Azure Verified Module (AVM) sub-vending pattern. See the Bicep template comments for details on why this approach was chosen.

## Documentation Structure

- [Subscription Vending Overview](Subscription-Vending/Subscription-Vending-Overview.md) - Learn about the architecture and components
- [Deploying Subscription Vending](Subscription-Vending/Deploying-Subscription-Vending.md) - Step-by-step deployment guide
- [Managing Subscription Vending](Subscription-Vending/Managing-Subscription-Vending.md) - Best practices for ongoing management

## Quick Links

- **Bicep Template**: `code/bicep/sub-vending/sub-vending.bicep`
- **Parameters File**: `code/bicep/sub-vending/sub-vending.bicepparam`
- **Pipeline**: `code/pipelines/sub-vending-pipeline.yaml`

## Key Concepts

- **Subscription Alias**: A unique identifier for the subscription following naming conventions
- **Management Group Assignment**: Automatic placement of subscriptions in the correct management group
- **Billing Scope**: Optional billing account configuration for EA and MCA scenarios
- **Workload Type**: Production or DevTest subscription classification
- **Standardized Tagging**: Consistent tags applied to all subscriptions for governance and cost management
