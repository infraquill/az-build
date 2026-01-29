# RBAC Requirements for Service Principal

This document outlines all Azure RBAC (Role-Based Access Control) requirements for the service principal used by Azure DevOps pipelines to deploy the infrastructure in this repository.

## Quick Reference

| Pipeline | Deployment Scope | Required Roles | Scope |
|----------|------------------|----------------|-------|
| mg-hierarchy | Tenant | Contributor | Tenant Root (`/`) |
| mg-hierarchy | Tenant | Management Group Contributor | Tenant Root MG |
| governance | Management Group | Resource Policy Contributor | Target MG |
| sub-vending | Management Group | Owner (for subscription creation) | Tenant Root MG + Billing |
| monitoring | Subscription | Contributor | Subscription |
| hub | Subscription | Contributor, User Access Administrator* | Subscription |
| spoke-networking | Subscription | Contributor | Subscription + Hub subscription |
| cloudops | Subscription | Contributor | Subscription |

*User Access Administrator only needed if deploying resources that require role assignments.

---

## Detailed Requirements by Pipeline

### 1. Management Group Hierarchy (`mg-hierarchy-pipeline`)

**Target Scope**: Tenant (uses `az deployment tenant`)

> **Note**: This pipeline deploys at **tenant scope** to avoid validation issues when creating management groups with parent MGs that don't exist yet. ARM validates all scopes before deployment starts, so management group scoped deployments would fail when targeting non-existent parent MGs.

| Role | Scope | Purpose |
|------|-------|---------|
| **Contributor** | Tenant Root (`/`) | `Microsoft.Resources/deployments/validate/action` for tenant deployments |
| **Management Group Contributor** | Tenant Root MG | Create, update, delete management groups |

#### Important: Tenant Root vs Tenant Root Management Group

- **Tenant Root** (`/`) - Required for `az deployment tenant` commands
- **Tenant Root Management Group** (`/providers/Microsoft.Management/managementGroups/<tenant-id>`) - Required for management group operations

Both scopes must have appropriate permissions for the mg-hierarchy deployment to work.

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
TENANT_ROOT_MG=$(az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv)

# Contributor at Tenant Root (for tenant-scoped deployments)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/"

# Management Group Contributor at Tenant Root MG
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Management Group Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG"
```

---

### 2. Governance (`governance-pipeline`)

**Target Scope**: Management Group

| Role | Scope | Purpose |
|------|-------|---------|
| **Resource Policy Contributor** | Target MG | Create/update policy assignments |
| **User Access Administrator** | Target MG | Grant permissions to policy managed identities (for remediation) |

#### Important Notes

- Policy assignments with `SystemAssigned` managed identity are created for MCSB and Canada PBMM
- If you plan to run remediation tasks, the policy's managed identity needs appropriate permissions
- The deploying SP needs `User Access Administrator` to grant those permissions

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
TARGET_MG="mg-arcnovus"  # Your organization root MG

# Resource Policy Contributor
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Resource Policy Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/$TARGET_MG"

# User Access Administrator (for managed identity role assignments)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "User Access Administrator" \
  --scope "/providers/Microsoft.Management/managementGroups/$TARGET_MG"
```

---

### 3. Subscription Vending (`sub-vending-pipeline`)

**Target Scope**: Management Group + Billing

| Role | Scope | Purpose |
|------|-------|---------|
| **Owner** | Tenant Root MG | Create subscriptions, assign to MGs, configure tags |
| **Billing Account Contributor** or **Invoice Section Contributor** | Billing Scope | Authorize subscription creation charges |

#### Special Considerations

Subscription creation requires:
1. **Azure RBAC**: Owner at management group level
2. **Billing Permissions**: Appropriate role on the billing account/invoice section

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
TENANT_ROOT_MG=$(az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv)

# Owner at Tenant Root MG (required for subscription creation)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG"
```

For billing permissions, use the Azure Portal:
1. Go to **Cost Management + Billing**
2. Navigate to your billing account/invoice section
3. Add the service principal as **Invoice Section Contributor** (MCA) or **Enrollment Account Administrator** (EA)

---

### 4. Monitoring Infrastructure (`monitoring-pipeline`)

**Target Scope**: Subscription

| Role | Scope | Purpose |
|------|-------|---------|
| **Contributor** | Management Subscription | Create resource groups, Log Analytics workspace |

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
SUBSCRIPTION_ID="<management-subscription-id>"

az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

### 5. Hub Infrastructure (`hub-pipeline`)

**Target Scope**: Subscription

| Role | Scope | Purpose |
|------|-------|---------|
| **Contributor** | Connectivity Subscription | Create all hub resources (VNet, Firewall, etc.) |
| **Network Contributor** | Connectivity MG | AVNM management group scope access |
| **User Access Administrator** | Connectivity Subscription | Role assignments for Key Vault RBAC, etc. |

#### Important Notes

- Azure Virtual Network Manager (AVNM) requires permissions at the management group scope it manages
- Key Vault with RBAC authorization may require role assignments
- DDoS Protection Plan creation requires Contributor

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
SUBSCRIPTION_ID="<connectivity-subscription-id>"
CONNECTIVITY_MG="mg-connectivity"

# Contributor on subscription
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Network Contributor on management group (for AVNM)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Network Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/$CONNECTIVITY_MG"

# User Access Administrator (if needed for RBAC-enabled resources)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

### 6. Spoke Networking (`spoke-networking-pipeline`)

**Target Scope**: Subscription (cross-subscription)

| Role | Scope | Purpose |
|------|-------|---------|
| **Contributor** | Spoke Subscription | Create spoke VNet and resources |
| **Network Contributor** | Hub Resource Group | Link spoke to hub Private DNS Zone |
| **Contributor** | Hub Resource Group | IPAM static CIDR allocation (if enabled) |

#### Cross-Subscription Considerations

Spoke networking deploys to multiple subscriptions:
- Spoke resources → Spoke subscription
- Private DNS Zone link → Hub subscription
- IPAM allocation → Hub subscription (if enabled)

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
SPOKE_SUBSCRIPTION_ID="<spoke-subscription-id>"
HUB_SUBSCRIPTION_ID="<hub-subscription-id>"
HUB_RESOURCE_GROUP="rg-hub-live-cac-001"

# Contributor on spoke subscription
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SPOKE_SUBSCRIPTION_ID"

# Network Contributor on hub resource group (for DNS zone link)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Network Contributor" \
  --scope "/subscriptions/$HUB_SUBSCRIPTION_ID/resourceGroups/$HUB_RESOURCE_GROUP"
```

---

### 7. CloudOps (`cloudops-pipeline`)

**Target Scope**: Subscription

| Role | Scope | Purpose |
|------|-------|---------|
| **Contributor** | CloudOps Subscription | Create DevCenter Project, Managed DevOps Pool |

#### Assignment Commands

```bash
SP_OBJECT_ID="<service-principal-object-id>"
SUBSCRIPTION_ID="<cloudops-subscription-id>"

az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

## Simplified Setup (Recommended for Initial Deployment)

For initial setup, you can assign broader permissions at the Tenant Root Management Group. This simplifies deployment but grants more access than strictly necessary.

### Minimum Viable Setup

```bash
SP_OBJECT_ID="<service-principal-object-id>"
TENANT_ROOT_MG=$(az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv)

# Owner at Tenant Root MG - covers most scenarios
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG"
```

> **⚠️ Security Note**: After initial deployment, consider reducing permissions to the minimum required for ongoing operations. The Owner role at tenant root is very powerful.

---

## Verifying Role Assignments

### List all role assignments for the service principal

```bash
SP_OBJECT_ID="<service-principal-object-id>"

# At management group scope
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>" \
  --output table

# At subscription scope
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "/subscriptions/<subscription-id>" \
  --output table

# All assignments
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --all \
  --output table
```

---

## Troubleshooting

### Common Error: "does not have authorization to perform action 'Microsoft.Resources/deployments/validate/action'"

```
The client does not have authorization to perform action 'Microsoft.Resources/deployments/validate/action'
over scope '/providers/Microsoft.Resources/deployments/mg-hierarchy'
```

**Cause**: Missing permissions at the **tenant root scope** (`/`) for tenant-scoped deployments.

**Solution**: Assign `Contributor` role at the tenant root:

```bash
az role assignment create --assignee "$SP_OBJECT_ID" --role "Contributor" --scope "/"
```

### Common Error: "Authorization failed for template resource"

```
Authorization failed for template resource 'mg-xxx' of type 'Microsoft.Resources/deployments'.
The client does not have permission to perform action 'Microsoft.Resources/deployments/write'
```

**Cause**: Missing `Contributor` role at management group scope, OR using management group scoped deployment for MGs that don't exist yet.

**Solution**: 
1. Use tenant-scoped deployment (`az deployment tenant`) instead of management group scoped
2. Assign `Contributor` role at the Tenant Root scope (`/`)

### Common Error: "The client does not have authorization to perform action 'Microsoft.Subscription/aliases/write'"

**Cause**: Missing permissions for subscription creation.

**Solution**: 
1. Assign `Owner` role at management group scope
2. Grant billing permissions via Azure Portal

### Common Error: "LinkedAuthorizationFailed"

**Cause**: Missing permissions for cross-subscription resource linking (e.g., Private DNS Zone links).

**Solution**: Assign `Network Contributor` or `Contributor` on the target resource group in the hub subscription.

---

## Role Definitions Reference

| Role | ID | Key Permissions |
|------|------|-----------------|
| Owner | `8e3af657-a8ff-443c-a75c-2fe8c4bcb635` | Full access including RBAC |
| Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` | Full access except RBAC |
| Management Group Contributor | `5d58bcaf-24a5-4b20-bdb6-eed9f69fbe4c` | Manage management groups |
| Resource Policy Contributor | `36243c78-bf99-498c-9df9-86d9f8d28608` | Manage policies |
| Network Contributor | `4d97b98b-1d4f-4787-a291-c67834d212e7` | Manage networks |
| User Access Administrator | `18d7d88d-d35e-4fb5-a5c3-7773c20a72d9` | Manage user access |
