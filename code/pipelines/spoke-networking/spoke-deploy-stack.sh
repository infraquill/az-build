#!/usr/bin/env bash
#
# spoke-deploy-stack.sh
# Location: code/pipelines/spoke-networking/
#
# Deploys the spoke networking deployment stack at subscription scope.
#
# Usage:
#   bash spoke-deploy-stack.sh \
#     <subscriptionId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <actionOnUnmanage> \
#     <workloadAlias> \
#     <environment> \
#     <locationCode> \
#     <instanceNumber> \
#     <location> \
#     <spokeVnetAddressSpace> \
#     <logAnalyticsWorkspaceResourceId> \
#     <owner> \
#     <managedBy> \
#     <hubPrivateDnsZoneName> \
#     <hubPrivateDnsZoneResourceId> \
#     <hubResourceGroupName> \
#     <hubSubscriptionId> \
#     <enableIpamAllocation> \
#     <hubAvnmName> \
#     <hubIpamPoolName>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed

set -euo pipefail

# Parameters (same as validate)
SUBSCRIPTION_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ACTION_ON_UNMANAGE="${7:-}"
WORKLOAD_ALIAS="${8:-}"
ENVIRONMENT="${9:-}"
LOCATION_CODE="${10:-}"
INSTANCE_NUMBER="${11:-}"
LOCATION="${12:-}"
SPOKE_VNET_ADDRESS_SPACE="${13:-}"
LOG_ANALYTICS_WORKSPACE_RESOURCE_ID="${14:-}"
OWNER="${15:-}"
MANAGED_BY="${16:-}"
HUB_PRIVATE_DNS_ZONE_NAME="${17:-}"
HUB_PRIVATE_DNS_ZONE_RESOURCE_ID="${18:-}"
HUB_RESOURCE_GROUP_NAME="${19:-}"
HUB_SUBSCRIPTION_ID="${20:-}"
ENABLE_IPAM_ALLOCATION="${21:-}"
HUB_AVNM_NAME="${22:-}"
HUB_IPAM_POOL_NAME="${23:-}"

PARAMS=""
# Core naming parameters
if [ -n "$WORKLOAD_ALIAS" ]; then
  PARAMS="$PARAMS --parameters workloadAlias='$WORKLOAD_ALIAS'"
fi
if [ -n "$ENVIRONMENT" ]; then
  PARAMS="$PARAMS --parameters environment='$ENVIRONMENT'"
fi
if [ -n "$LOCATION_CODE" ]; then
  PARAMS="$PARAMS --parameters locationCode='$LOCATION_CODE'"
fi
if [ -n "$INSTANCE_NUMBER" ]; then
  PARAMS="$PARAMS --parameters instanceNumber='$INSTANCE_NUMBER'"
fi
if [ -n "$LOCATION" ]; then
  PARAMS="$PARAMS --parameters location='$LOCATION'"
fi
# Spoke VNet configuration
if [ -n "$SPOKE_VNET_ADDRESS_SPACE" ]; then
  PARAMS="$PARAMS --parameters spokeVnetAddressSpace='$SPOKE_VNET_ADDRESS_SPACE'"
fi
# Monitoring
if [ -n "$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters logAnalyticsWorkspaceResourceId='$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'"
fi
# Ownership
if [ -n "$OWNER" ]; then
  PARAMS="$PARAMS --parameters owner='$OWNER'"
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS="$PARAMS --parameters managedBy='$MANAGED_BY'"
fi
# Hub infrastructure references
if [ -n "$HUB_PRIVATE_DNS_ZONE_NAME" ]; then
  PARAMS="$PARAMS --parameters hubPrivateDnsZoneName='$HUB_PRIVATE_DNS_ZONE_NAME'"
fi
if [ -n "$HUB_PRIVATE_DNS_ZONE_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters hubPrivateDnsZoneResourceId='$HUB_PRIVATE_DNS_ZONE_RESOURCE_ID'"
fi
if [ -n "$HUB_RESOURCE_GROUP_NAME" ]; then
  PARAMS="$PARAMS --parameters hubResourceGroupName='$HUB_RESOURCE_GROUP_NAME'"
fi
if [ -n "$HUB_SUBSCRIPTION_ID" ]; then
  PARAMS="$PARAMS --parameters hubSubscriptionId='$HUB_SUBSCRIPTION_ID'"
fi
# IPAM configuration
PARAMS="$PARAMS --parameters enableIpamAllocation=$ENABLE_IPAM_ALLOCATION"
if [ -n "$HUB_AVNM_NAME" ]; then
  PARAMS="$PARAMS --parameters hubAvnmName='$HUB_AVNM_NAME'"
fi
if [ -n "$HUB_IPAM_POOL_NAME" ]; then
  PARAMS="$PARAMS --parameters hubIpamPoolName='$HUB_IPAM_POOL_NAME'"
fi

az stack sub create \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes \
  $PARAMS
