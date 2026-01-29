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
    id: 'mg-landing-zone'
    displayName: 'Landing Zone'
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
  {
    id: 'mg-corp-prod'
    displayName: 'Corp Production'
    parentId: 'mg-landing-zone'
  }
  {
    id: 'mg-corp-non-prod'
    displayName: 'Corp Non-Production'
    parentId: 'mg-landing-zone'
  }
  {
    id: 'mg-online-prod'
    displayName: 'Online Production'
    parentId: 'mg-landing-zone'
  }
  {
    id: 'mg-online-non-prod'
    displayName: 'Online Non-Production'
    parentId: 'mg-landing-zone'
  }
]
