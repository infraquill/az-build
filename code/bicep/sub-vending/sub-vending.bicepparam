using 'sub-vending.bicep'

param projectName = 'example-project'

param managementGroupId = 'your-management-group-id'

param billingScope = ''

param workload = 'Production'

param workloadAlias = 'example-project'

param environment = 'dev'

param locationCode = 'cac'

param instanceNumber = '001'

param owner = 'example-owner'

param managedBy = 'Bicep'

// Optional: Set to an existing subscription ID to move it instead of creating new
param existingSubscriptionId = ''
