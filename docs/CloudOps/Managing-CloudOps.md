# Managing CloudOps Infrastructure

This guide covers ongoing management and operations for the CloudOps Managed DevOps Pools infrastructure.

## Understanding Scale-to-Zero

Managed DevOps Pools have native scale-to-zero support, which is a key cost optimization feature.

### How Scale-to-Zero Works

1. **Queue Monitoring**: The pool continuously monitors the Azure DevOps job queue
2. **Idle Detection**: When no jobs are queued and agents are idle, the pool scales down
3. **Zero Agents**: All agents are deallocated, resulting in zero compute costs
4. **Automatic Scale-Up**: When a job is queued, agents are automatically provisioned
5. **Job Execution**: The job runs once an agent is available

### Scale-to-Zero Behavior

| Scenario | Behavior |
|----------|----------|
| Jobs queued | Agents provisioned automatically (2-5 min) |
| Jobs complete, queue empty | Agents scale down after grace period |
| No activity | Pool scales to zero agents |
| New job queued | Agent provisioned, job starts |

### Cost Implications

- **Zero cost** when no agents are running
- Pay only for actual compute time during job execution
- No idle agent costs
- Perfect for variable or intermittent workloads

## Common Management Tasks

### Adjusting Maximum Concurrency

To change the maximum number of concurrent agents:

1. Update the pipeline parameter `poolMaximumConcurrency`
2. Re-run the pipeline with `deploymentStage: Deploy`

Or via Azure CLI:
```bash
az resource update \
  --resource-type "Microsoft.DevOpsInfrastructure/pools" \
  --name mdp-cloudops-live-cac-001 \
  --resource-group rg-cloudops-live-cac-001 \
  --subscription <cloudops-subscription-id> \
  --set properties.maximumConcurrency=8
```

### Changing VM Size

To change the VM SKU for pool agents:

1. Update the pipeline parameter `poolAgentSkuName`
2. Re-run the pipeline with `deploymentStage: Deploy`

Available sizes:
- `Standard_D2s_v5` - Light workloads
- `Standard_D4s_v5` - Standard workloads (recommended)
- `Standard_D8s_v5` - Heavy build workloads

### Changing Agent Image

To change the agent image:

1. Update the pipeline parameter `poolImageName`
2. Re-run the pipeline with `deploymentStage: Deploy`

Available images:
- `ubuntu-22.04/latest` - Recommended
- `ubuntu-24.04/latest` - Latest Ubuntu
- `windows-2022/latest` - Windows builds
- `windows-2019/latest` - Legacy Windows

### Enabling/Disabling Scale-to-Zero

To toggle scale-to-zero:

1. Update the pipeline parameter `enableScaleToZero`
2. Re-run the pipeline with `deploymentStage: Deploy`

When disabled, the pool uses `Balanced` prediction preference instead of `MostCostEffective`.

## Viewing Deployment Stack

Check the current state of the deployment stack:

```bash
az stack sub show \
  --name "stack-cloudops-live-cac-001" \
  --subscription <cloudops-subscription-id>
```

View all resources managed by the stack:

```bash
az stack sub show \
  --name "stack-cloudops-live-cac-001" \
  --subscription <cloudops-subscription-id> \
  --query "resources[].{Name:id, Type:type}" -o table
```

## Monitoring

### Check Pool Status

View pool status via Azure CLI:

```bash
az resource show \
  --resource-type "Microsoft.DevOpsInfrastructure/pools" \
  --name mdp-cloudops-live-cac-001 \
  --resource-group rg-cloudops-live-cac-001 \
  --subscription <cloudops-subscription-id>
```

### Azure DevOps Agent Status

Check agent status in Azure DevOps:

1. Go to **Organization Settings** > **Agent Pools**
2. Select the pool (e.g., `mdp-cloudops-live-cac-001`)
3. View agent status and job history

**Note**: With scale-to-zero enabled, you may see no agents when the pool is idle. This is expected behavior.

### View Pool Metrics

Monitor pool metrics in Azure Portal:

1. Navigate to the Managed DevOps Pool resource
2. Go to **Metrics**
3. Available metrics:
   - Running agents count
   - Job queue depth
   - Agent provisioning time
   - Job execution time

### Azure DevOps REST API

Query agent pool status:

```bash
curl -u :<PAT> \
  "https://dev.azure.com/<org>/_apis/distributedtask/pools?poolName=mdp-cloudops-live-cac-001&api-version=7.0"
```

## Troubleshooting

### Agents Not Provisioning

**Symptom**: Jobs queued but no agents provisioning

**Diagnosis**:
1. Check pool status in Azure Portal
2. Check pool provisioning logs
3. Verify Azure DevOps organization connection

**Resolution**:
1. Verify pool is not paused
2. Check quota limits for VM SKU
3. Review pool activity logs for errors
4. Verify network connectivity

### Long Agent Provisioning Time

**Symptom**: Agents take longer than 5 minutes to provision

**Possible Causes**:
1. Region capacity constraints
2. Large image download
3. Network Connection issues

**Resolution**:
1. Check Azure status for region issues
2. Consider using a different VM SKU
3. Verify Network Connection status

### Job Failures

**Symptom**: Jobs fail after agent is assigned

**Diagnosis**:
1. Check job logs in Azure DevOps
2. SSH to agent (if available) to check state
3. Review agent capabilities

**Resolution**:
1. Check if required tools are in the image
2. Consider custom image if tools missing
3. Review job requirements vs agent capabilities

### Pool Shows Offline

**Symptom**: Pool shows as offline in Azure DevOps

**Possible Causes**:
1. Azure DevOps organization connection lost
2. Pool resource unhealthy
3. Permission issues

**Resolution**:
1. Check pool resource health in Azure Portal
2. Verify Azure DevOps organization URL
3. Re-deploy the pool via pipeline

### Network Connectivity Issues

**Symptom**: Agents cannot reach spoke VNets or Azure services

**Diagnosis**:
1. Check Network Connection status
2. Verify subnet configuration
3. Review NSG rules

**Resolution**:
1. Verify AVNM connectivity configuration
2. Check Network Connection in DevCenter
3. Update NSG rules if needed

## Security Management

### Pool Identity Permissions

Managed DevOps Pools create a managed identity. View and manage permissions:

```bash
# Find the pool's managed identity in Azure Portal
# Navigate to: Pool Resource > Identity

# Grant permissions
az role assignment create \
  --role "Contributor" \
  --assignee-object-id <pool-identity-principal-id> \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/<target-subscription-id>"
```

### Audit Pool Access

Review who can access the pool in Azure DevOps:

1. Go to **Organization Settings** > **Agent Pools**
2. Select the pool
3. Go to **Security** tab
4. Review and manage permissions

### Project Scoping

To restrict pool access to specific projects:

1. Update `azureDevOpsProjectNames` parameter with project list
2. Re-deploy via pipeline

## Maintenance

### Planned Maintenance

1. **Communicate** - Notify users of maintenance window
2. **Wait for idle** - Allow running jobs to complete
3. **Perform maintenance** - Update pool configuration
4. **Verify** - Ensure pool is healthy and agents can run

### Image Updates

Managed DevOps Pools automatically use the latest version of well-known images. To manually trigger image refresh:

1. Re-run the pipeline with `deploymentStage: Deploy`
2. New agents will use the latest image version

### Pool Recreation

If pool needs complete recreation:

1. Delete the deployment stack:
   ```bash
   az stack sub delete \
     --name "stack-cloudops-live-cac-001" \
     --subscription <cloudops-subscription-id> \
     --yes
   ```
2. Re-run the cloudops-pipeline with `deploymentStage: Deploy`

## Operational Best Practices

### 1. Monitor Costs

- Review Azure Cost Management for pool costs
- Track agent hours vs. job hours
- Ensure scale-to-zero is working

### 2. Capacity Planning

- Monitor job queue depth trends
- Adjust `poolMaximumConcurrency` based on demand
- Consider multiple pools for different workload types

### 3. Security

- Review pool permissions quarterly
- Audit job execution logs
- Keep Azure DevOps organization permissions tight

### 4. Testing

- Test pool configuration changes in non-production first
- Validate agent capabilities meet job requirements
- Test scale-up time meets SLA requirements

## Disaster Recovery

### Backup Strategy

Managed DevOps Pools are stateless:
- All configuration is in IaC (git)
- Pool can be recreated from Bicep templates
- No data backup required

### Recovery Procedure

1. **Full Redeploy**:
   - Run Stage 3 (devcenter) pipeline if DevCenter lost
   - Run Stage 4 (cloudops) pipeline to redeploy pool
   - Pool will reconnect to Azure DevOps automatically

2. **Pool Recreation**:
   - Delete existing stack (if corrupted)
   - Re-run cloudops-pipeline
   - Verify pool appears in Azure DevOps

### RTO/RPO

| Scenario | RTO | RPO |
|----------|-----|-----|
| Agent failure | Automatic (new agent) | 0 (stateless) |
| Pool failure | 15-30 minutes | 0 (IaC) |
| DevCenter failure | 30-60 minutes | 0 (IaC) |

## Related Documentation

- [CloudOps Overview](CloudOps-Overview.md) - Architecture details
- [Deploying CloudOps](Deploying-CloudOps.md) - Initial deployment guide
- [Spoke Infrastructure](../Spoke-Infrastructure.md) - Spoke networking details
- [Hub Infrastructure](../Hub-Infrastructure.md) - Hub configuration
