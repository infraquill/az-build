// =============================================================================
// Management Group Hierarchy Parameters
// =============================================================================
// Deploy with: az deployment tenant create --location <region> \
//              --template-file mg-hierarchy.bicep --parameters mg-hierarchy.bicepparam
//
// RBAC Requirements (assign before running):
//   az role assignment create --assignee "<sp-object-id>" --role "Contributor" --scope "/"
//   az role assignment create --assignee "<sp-object-id>" --role "Management Group Contributor" \
//     --scope "/providers/Microsoft.Management/managementGroups/<tenant-id>"
// =============================================================================

using 'mg-hierarchy.bicep'

param tenantRootManagementGroupId = 'your-tenant-id'
param orgName = 'org'
param orgDisplayName = 'Organization Name'

param managementGroups = [
  {
    id: 'mg-${orgName}'
    displayName: orgDisplayName
    parentId: tenantRootManagementGroupId
  }
  {
    id: 'mg-platform'
    displayName: 'Platform'
    parentId: 'mg-${orgName}'
  }
  {
    id: 'mg-landing-zones'
    displayName: 'Landing Zones'
    parentId: 'mg-${orgName}'
  }
  {
    id: 'mg-sandbox'
    displayName: 'Sandbox'
    parentId: 'mg-${orgName}'
  }
  {
    id: 'mg-decommissioned'
    displayName: 'Decommissioned'
    parentId: 'mg-${orgName}'
  }
  // Platform Children
  {
    id: 'mg-identity'
    displayName: 'Identity'
    parentId: 'mg-platform'
  }
  {
    id: 'mg-management'
    displayName: 'Management'
    parentId: 'mg-platform'
  }
  {
    id: 'mg-connectivity'
    displayName: 'Connectivity'
    parentId: 'mg-platform'
  }
  // Landing Zone Containers
  {
    id: 'mg-corp'
    displayName: 'Corp'
    parentId: 'mg-landing-zones'
  }
  {
    id: 'mg-online'
    displayName: 'Online'
    parentId: 'mg-landing-zones'
  }
  // Corp Environments (Regulated Split)
  {
    id: 'mg-corp-prod'
    displayName: 'Corp Production'
    parentId: 'mg-corp'
  }
  {
    id: 'mg-corp-non-prod'
    displayName: 'Corp Non-Production'
    parentId: 'mg-corp'
  }
  // Online Environments (Regulated Split)
  {
    id: 'mg-online-prod'
    displayName: 'Online Production'
    parentId: 'mg-online'
  }
  {
    id: 'mg-online-non-prod'
    displayName: 'Online Non-Production'
    parentId: 'mg-online'
  }
]
