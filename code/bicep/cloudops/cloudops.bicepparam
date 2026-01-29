using 'cloudops.bicep'

// ============================================================================
// CLOUDOPS WORKLOAD INFRASTRUCTURE PARAMETERS - MANAGED DEVOPS POOLS
// Default values for CloudOps Managed DevOps Pool deployment
// Prerequisites:
// - CloudOps subscription created via sub-vending pipeline (Stage 1)
// - CloudOps spoke networking deployed via spoke-networking pipeline (Stage 2)
// - DevCenter deployed via cloudops-devcenter pipeline (Stage 3)
// ============================================================================

// Core naming parameters
// These identify the CloudOps workload
param workloadAlias = 'cloudops'

param environment = 'live'

param locationCode = 'cac'

param instanceNumber = '001'

// Location
param location = 'canadacentral'

// Ownership and management
param owner = 'platform-team@organization.com'

param managedBy = 'Bicep'

// ============================================================================
// DEVCENTER REFERENCES (from Stage 3 deployment)
// These values must be provided from DevCenter deployment outputs
// ============================================================================

// The resource ID of the DevCenter
// Format: /subscriptions/{subId}/resourceGroups/{rgName}/providers/Microsoft.DevCenter/devcenters/{devCenterName}
// Get from devcenter deployment outputs: devCenterResourceId
param devCenterResourceId = ''

// ============================================================================
// SPOKE NETWORKING REFERENCES (from Stage 2 deployment)
// These values must be provided from spoke-networking deployment outputs
// ============================================================================

// The resource ID of the subnet where pool agents will be deployed
// Format: /subscriptions/{subId}/resourceGroups/{rgName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}
// Get from spoke-networking deployment outputs: spokeVnetSubnetResourceIds[0] or specific subnet
param poolSubnetResourceId = ''

// ============================================================================
// MANAGED DEVOPS POOL CONFIGURATION
// Azure Managed DevOps Pool settings with native scale-to-zero support
// ============================================================================

// Maximum number of concurrent agents (minimum is 1)
// Recommended: Start with 2-4 agents, scale based on workload
// The pool will automatically scale between 0 and this maximum based on queue depth
param poolMaximumConcurrency = 4

// VM SKU size for pool agents
// Recommended for DevOps agents:
// - Standard_D2s_v5: 2 vCPU, 8 GB RAM (good for light workloads)
// - Standard_D4s_v5: 4 vCPU, 16 GB RAM (recommended for most workloads)
// - Standard_D8s_v5: 8 vCPU, 32 GB RAM (for heavy build workloads)
param poolAgentSkuName = 'Standard_D4s_v5'

// Pool image - pre-configured Azure DevOps agent images
// Options:
// - ubuntu-22.04/latest: Ubuntu 22.04 LTS with Azure DevOps agent (recommended)
// - ubuntu-24.04/latest: Ubuntu 24.04 LTS with Azure DevOps agent
// - windows-2022/latest: Windows Server 2022 with Azure DevOps agent
// - windows-2019/latest: Windows Server 2019 with Azure DevOps agent
param poolImageName = 'ubuntu-22.04/latest'

// Enable scale-to-zero for cost optimization
// When true: Pool scales to 0 agents when no jobs are queued (MostCostEffective)
// When false: Pool maintains some agent capacity (Balanced prediction)
param enableScaleToZero = true

// ============================================================================
// AZURE DEVOPS CONFIGURATION
// Settings for Azure DevOps integration
// ============================================================================

// Azure DevOps organization URL
// Format: https://dev.azure.com/yourorganization
param azureDevOpsOrganizationUrl = ''

// Optional: Scope the pool to specific Azure DevOps projects
// Leave empty to make the pool available organization-wide
// Example: ['Project1', 'Project2']
param azureDevOpsProjectNames = []
