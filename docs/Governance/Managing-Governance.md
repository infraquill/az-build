# Managing Governance

This guide covers ongoing management, monitoring, and compliance reporting for Azure Policy assignments.

> **Design Philosophy:** Policies are used as a **reporting mechanism** to identify compliance gaps. Remediation should be performed through IaC pipelines, not through Azure Policy remediation tasks. This keeps all infrastructure changes centralized, traceable, and under version control.

## Compliance Monitoring

### Azure Portal Dashboard

1. Navigate to **Azure Policy** in the Azure Portal
2. Select **Compliance** in the left menu
3. Filter by scope to view specific management groups or subscriptions
4. Review the compliance dashboard:
   - Overall compliance percentage
   - Non-compliant resources count
   - Non-compliant policies count

### Compliance by Initiative

View compliance for specific policy initiatives:

1. In Azure Policy, select **Compliance**
2. Click on the initiative name (e.g., "Microsoft Cloud Security Benchmark - Audit")
3. Review:
   - Per-policy compliance status
   - Non-compliant resources by policy
   - Compliance trend over time

### Azure CLI Compliance Queries

```bash
# Get compliance summary for management group
az policy state summarize \
  --management-group "mg-platform"

# List non-compliant resources
az policy state list \
  --management-group "mg-platform" \
  --filter "complianceState eq 'NonCompliant'" \
  --output table

# Get compliance for specific policy assignment
az policy state list \
  --policy-assignment "mcsb-audit-live" \
  --management-group "mg-platform" \
  --output table
```

### Azure Resource Graph Queries

Query compliance data at scale using Azure Resource Graph:

```kusto
// Count non-compliant resources by policy
PolicyResources
| where type == 'microsoft.policyinsights/policystates'
| where properties.complianceState == 'NonCompliant'
| summarize count() by tostring(properties.policyDefinitionName)
| order by count_ desc

// List non-compliant resources with details
PolicyResources
| where type == 'microsoft.policyinsights/policystates'
| where properties.complianceState == 'NonCompliant'
| project 
    resourceId = properties.resourceId,
    policyName = properties.policyDefinitionName,
    resourceType = properties.resourceType,
    subscriptionId = properties.subscriptionId
```

## Remediation Strategy: IaC-First Approach

### Why IaC-Driven Remediation?

> **Recommendation:** Use compliance data to identify gaps, then remediate through IaC pipelines—not through Azure Policy remediation tasks.

| Approach | IaC-Driven (Recommended) | Policy Remediation (Not Recommended) |
|----------|--------------------------|--------------------------------------|
| **Control** | Changes go through pipelines with review/approval | Changes happen automatically without review |
| **Traceability** | All changes are in source control | Changes are not reflected in IaC code |
| **Drift** | IaC remains the source of truth | Creates drift between IaC and actual state |
| **Predictability** | Changes are explicit and planned | Changes can happen unexpectedly |
| **Rollback** | Easy via source control and redeployment | Requires manual intervention |

### Recommended Remediation Workflow

1. **Identify Non-Compliant Resources**
   - Review Azure Policy compliance dashboard
   - Use Resource Graph queries to list non-compliant resources
   - Export compliance data for analysis

2. **Analyze Root Cause**
   - Determine why resources are non-compliant
   - Check if IaC templates are missing required configurations
   - Identify patterns across multiple resources

3. **Update IaC Templates**
   - Modify Bicep templates to include compliant configurations
   - Add diagnostic settings, encryption, network rules, etc.
   - Follow existing patterns in the codebase

4. **Deploy Through Pipelines**
   - Submit changes through normal PR/review process
   - Run validation and what-if stages
   - Deploy to bring resources into compliance

5. **Verify Compliance**
   - Trigger an on-demand compliance scan
   - Confirm resources now show as compliant
   - Document changes for audit trail

### Common Compliance Gaps and IaC Solutions

| Compliance Gap | IaC Solution |
|----------------|--------------|
| Missing diagnostic settings | Add `diagnosticSettings` to resource modules |
| Storage not using HTTPS | Set `supportsHttpsTrafficOnly: true` |
| Missing encryption | Configure encryption settings in Bicep |
| Public network access | Set `publicNetworkAccess: 'Disabled'` |
| Missing tags | Add required tags to resource definitions |
| NSG flow logs disabled | Deploy NSG flow logs via hub/spoke templates |

### Why NOT to Use Policy Remediation Tasks

Azure Policy supports automatic remediation, but we recommend against using it:

1. **Configuration Drift**: Remediation changes resources outside of IaC, causing your Bicep templates to no longer reflect actual state
2. **Unpredictable Timing**: Remediation can run at any time, potentially during critical operations
3. **No Review Process**: Changes bypass code review and approval workflows
4. **Difficult Rollback**: Reverting remediation changes requires manual intervention
5. **Partial Fixes**: Remediation may fix symptoms without addressing root cause in IaC

> **If you must use policy remediation** (e.g., for one-time cleanup of legacy resources), immediately update your IaC templates to match the remediated state to prevent drift.

## Policy Exemptions

### When to Use Exemptions

Use policy exemptions when:

- A resource legitimately cannot comply (e.g., legacy system)
- Compliance will be achieved later (with expiration date)
- Alternative controls are in place
- Resource is temporary or in decommissioning

### Creating Exemptions

#### Azure Portal

1. Navigate to **Azure Policy** > **Compliance**
2. Select the non-compliant resource
3. Click **Create exemption**
4. Configure:
   - Name and description
   - Exemption category (Waiver or Mitigated)
   - Expiration date (optional but recommended)
   - Policy definition (specific policy or all)

#### Azure CLI

```bash
# Create exemption for specific resource
az policy exemption create \
  --name "legacy-storage-exemption" \
  --policy-assignment "mcsb-audit-live" \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>" \
  --exemption-category "Waiver" \
  --description "Legacy storage account pending migration. Expires Q2 2025." \
  --expires-on "2025-06-30"

# Create exemption for entire subscription
az policy exemption create \
  --name "sandbox-exemption" \
  --policy-assignment "mcsb-audit-live" \
  --scope "/subscriptions/<sandbox-subscription-id>" \
  --exemption-category "Waiver" \
  --description "Sandbox subscription exempt from MCSB enforcement"
```

### Exemption Categories

| Category | Use Case |
|----------|----------|
| **Waiver** | Accepting the risk; no alternative controls |
| **Mitigated** | Alternative controls are in place |

### Managing Exemptions

```bash
# List all exemptions
az policy exemption list \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform"

# Delete expired exemption
az policy exemption delete \
  --name "legacy-storage-exemption" \
  --scope "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>"
```

## Updating Policy Assignments

### Enforcement Mode

> **Recommendation:** Keep enforcement mode at `DoNotEnforce` permanently.

The `enforcementMode` parameter is available but we recommend **not changing it** to `Default`. Enforcement mode is better handled through:

- IaC pipeline validation and linting
- Code review requirements
- Deployment approval gates
- Post-deployment compliance verification

If you have a specific requirement to enable enforcement (e.g., regulatory mandate), be aware of the implications:

```bash
# NOT RECOMMENDED: Enable enforcement mode
az deployment mg create \
  --name "governance-enforcement-update" \
  --management-group-id "mg-platform" \
  --location canadacentral \
  --template-file code/bicep/governance/governance.bicep \
  --parameters code/bicep/governance/governance.bicepparam \
  --parameters enforcementMode="Default"
```

> **Warning:** Enabling enforcement can block legitimate IaC deployments. Policy evaluation timing may cause race conditions where resources are blocked before all configurations are applied.

### Enabling/Disabling Policies

To enable or disable specific policy initiatives:

```bash
# Disable Canada PBMM (keep MCSB enabled)
az deployment mg create \
  --name "governance-disable-pbmm" \
  --management-group-id "mg-platform" \
  --location canadacentral \
  --template-file code/bicep/governance/governance.bicep \
  --parameters code/bicep/governance/governance.bicepparam \
  --parameters enableMCSB=true \
  --parameters enableCanadaPBMM=false
```

### Changing Target Scope

To apply policies to a different management group:

1. Run the governance pipeline with the new `managementGroupId` parameter
2. This creates new policy assignments at the new scope
3. Manually delete old assignments if no longer needed

## Deleting Policy Assignments

### Azure Portal

1. Navigate to **Azure Policy** > **Assignments**
2. Find the policy assignment
3. Click the ellipsis (...) menu
4. Select **Delete assignment**

### Azure CLI

```bash
# Delete MCSB assignment
az policy assignment delete \
  --name "mcsb-audit-live" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform"

# Delete Canada PBMM assignment
az policy assignment delete \
  --name "canada-pbmm-audit-live" \
  --scope "/providers/Microsoft.Management/managementGroups/mg-platform"
```

## Alerting and Notifications

### Azure Monitor Alerts

Create alerts for compliance state changes:

1. Navigate to **Azure Monitor** > **Alerts**
2. Click **Create** > **Alert rule**
3. Select scope (management group or subscription)
4. Configure condition:
   - Signal type: Activity Log
   - Signal name: "Create or Update Policy Assignment"
5. Configure action group for notifications
6. Create the alert rule

### Policy Compliance Change Alert (Activity Log)

```json
{
  "category": "Policy",
  "operationName": "Microsoft.PolicyInsights/policyStates/queryResults/action",
  "properties": {
    "complianceState": "NonCompliant"
  }
}
```

## Best Practices

### Keep Policies in Audit Mode

> **Recommendation:** Deploy policies in audit mode and keep them there permanently.

Policies should serve as a **compliance reporting mechanism**, not an enforcement or remediation tool. This approach:

- Uses IaC as the single source of truth for infrastructure
- Prevents configuration drift from policy remediation
- Keeps all changes traceable and under version control
- Avoids blocking deployments due to policy timing issues

### Scope Strategy

| Environment | Recommended Approach |
|-------------|---------------------|
| Sandbox | Audit only (or exempt) |
| Development | Audit only |
| Test/UAT | Audit only |
| Production | Audit only |

All environments use audit mode. Compliance is enforced through:
- IaC pipeline validation (Bicep linting, what-if analysis)
- Code review requirements
- Deployment approvals
- Post-deployment compliance verification

### Using Compliance Data

Leverage compliance reports to:

1. **Identify IaC gaps** - Find resources that need template updates
2. **Generate reports** - Provide compliance evidence for audits
3. **Track trends** - Monitor compliance improvement over time
4. **Prioritize work** - Focus IaC improvements on high-impact areas

### Documentation

- Document all exemptions with business justification
- Set expiration dates on exemptions
- Review exemptions quarterly
- Track IaC remediation progress in your backlog

### Regular Reviews

- **Weekly**: Review new non-compliant resources and create IaC tasks
- **Monthly**: Review compliance trends and IaC remediation progress
- **Quarterly**: Review and renew/remove exemptions
- **Annually**: Review policy effectiveness and update initiatives

## Troubleshooting

### Compliance Not Updating

1. Trigger an on-demand compliance scan:
   ```bash
   az policy state trigger-scan --no-wait
   ```
2. Wait for scan to complete (can take several hours for large scopes)
3. Check Activity Log for scan completion

### Policy Not Evaluating Resources

1. Verify the resource is within the policy scope
2. Check for policy exemptions on the resource
3. Ensure the policy definition conditions match the resource type
4. Review the policy rule logic for evaluation criteria

### Resources Still Non-Compliant After IaC Update

1. Verify the IaC deployment completed successfully
2. Trigger an on-demand compliance scan
3. Check if the policy evaluates the specific configuration you changed
4. Review the policy definition to understand evaluation criteria
5. Some policies may have delays in evaluation (up to 24 hours)

## Related Documentation

- [Governance Overview](Governance-Overview.md) - Architecture and components
- [Deploying Governance](Deploying-Governance.md) - Deployment guide
- [RBAC Requirements](../RBAC-Requirements.md) - Permission requirements
