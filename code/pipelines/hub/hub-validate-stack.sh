#!/usr/bin/env bash
#
# hub-validate-stack.sh
# Location: code/pipelines/hub/
#
# Validates the hub deployment stack at subscription scope.
#
# Usage:
#   bash hub-validate-stack.sh \
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
#     <privateDnsZoneName> \
#     <hubVnetAddressSpace> \
#     <logAnalyticsWorkspaceResourceId> \
#     <owner> \
#     <managedBy> \
#     <avnmManagementGroupId> \
#     <enableAppGatewayWAF> \
#     <enableFrontDoor> \
#     <enableVpnGateway> \
#     <enableAzureFirewall> \
#     <enableDDoSProtection> \
#     <enableDnsResolver> \
#     <enableIpamPool> \
#     <ipamPoolAddressSpace> \
#     <ipamPoolDescription> \
#     <vpnClientAddressPoolPrefix> \
#     <azureFirewallTier> \
#     <keyVaultAdminPrincipalId>
#
# Exit codes:
#   0 - Validation succeeded
#   1 - Validation failed

set -euo pipefail

# Parameters
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
PRIVATE_DNS_ZONE_NAME="${13:-}"
HUB_VNET_ADDRESS_SPACE="${14:-}"
LOG_ANALYTICS_WORKSPACE_RESOURCE_ID="${15:-}"
OWNER="${16:-}"
MANAGED_BY="${17:-}"
AVNM_MANAGEMENT_GROUP_ID="${18:-}"
ENABLE_APP_GATEWAY_WAF="${19:-}"
ENABLE_FRONT_DOOR="${20:-}"
ENABLE_VPN_GATEWAY="${21:-}"
ENABLE_AZURE_FIREWALL="${22:-}"
ENABLE_DDOS_PROTECTION="${23:-}"
ENABLE_DNS_RESOLVER="${24:-}"
ENABLE_IPAM_POOL="${25:-}"
IPAM_POOL_ADDRESS_SPACE="${26:-}"
IPAM_POOL_DESCRIPTION="${27:-}"
VPN_CLIENT_ADDRESS_POOL_PREFIX="${28:-}"
AZURE_FIREWALL_TIER="${29:-}"
KEY_VAULT_ADMIN_PRINCIPAL_ID="${30:-}"

# Build parameters array for additional parameters (override .bicepparam defaults)
PARAMS_ARRAY=()
if [ -n "$WORKLOAD_ALIAS" ]; then
  PARAMS_ARRAY+=(--parameters "workloadAlias=$WORKLOAD_ALIAS")
fi
if [ -n "$ENVIRONMENT" ]; then
  PARAMS_ARRAY+=(--parameters "environment=$ENVIRONMENT")
fi
if [ -n "$LOCATION_CODE" ]; then
  PARAMS_ARRAY+=(--parameters "locationCode=$LOCATION_CODE")
fi
if [ -n "$INSTANCE_NUMBER" ]; then
  PARAMS_ARRAY+=(--parameters "instanceNumber=$INSTANCE_NUMBER")
fi
if [ -n "$LOCATION" ]; then
  PARAMS_ARRAY+=(--parameters "location=$LOCATION")
fi
if [ -n "$PRIVATE_DNS_ZONE_NAME" ]; then
  PARAMS_ARRAY+=(--parameters "privateDnsZoneName=$PRIVATE_DNS_ZONE_NAME")
fi
if [ -n "$HUB_VNET_ADDRESS_SPACE" ]; then
  PARAMS_ARRAY+=(--parameters "hubVnetAddressSpace=$HUB_VNET_ADDRESS_SPACE")
fi
if [ -n "$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID" ]; then
  PARAMS_ARRAY+=(--parameters "logAnalyticsWorkspaceResourceId=$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID")
fi
if [ -n "$OWNER" ]; then
  PARAMS_ARRAY+=(--parameters "owner=$OWNER")
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS_ARRAY+=(--parameters "managedBy=$MANAGED_BY")
fi
if [ -n "$AVNM_MANAGEMENT_GROUP_ID" ]; then
  PARAMS_ARRAY+=(--parameters "avnmManagementGroupId=$AVNM_MANAGEMENT_GROUP_ID")
fi
# Optional resource flags (booleans must be lowercase true/false)
PARAMS_ARRAY+=(--parameters "enableAppGatewayWAF=$(echo "$ENABLE_APP_GATEWAY_WAF" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableFrontDoor=$(echo "$ENABLE_FRONT_DOOR" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableVpnGateway=$(echo "$ENABLE_VPN_GATEWAY" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableAzureFirewall=$(echo "$ENABLE_AZURE_FIREWALL" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableDDoSProtection=$(echo "$ENABLE_DDOS_PROTECTION" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableDnsResolver=$(echo "$ENABLE_DNS_RESOLVER" | tr '[:upper:]' '[:lower:]')")
PARAMS_ARRAY+=(--parameters "enableIpamPool=$(echo "$ENABLE_IPAM_POOL" | tr '[:upper:]' '[:lower:]')")
if [ -n "$IPAM_POOL_ADDRESS_SPACE" ]; then
  PARAMS_ARRAY+=(--parameters "ipamPoolAddressSpace=$IPAM_POOL_ADDRESS_SPACE")
fi
if [ -n "$IPAM_POOL_DESCRIPTION" ]; then
  PARAMS_ARRAY+=(--parameters "ipamPoolDescription=$IPAM_POOL_DESCRIPTION")
fi
# Optional resource configuration
if [ -n "$VPN_CLIENT_ADDRESS_POOL_PREFIX" ]; then
  PARAMS_ARRAY+=(--parameters "vpnClientAddressPoolPrefix=$VPN_CLIENT_ADDRESS_POOL_PREFIX")
fi
if [ -n "$AZURE_FIREWALL_TIER" ]; then
  PARAMS_ARRAY+=(--parameters "azureFirewallTier=$AZURE_FIREWALL_TIER")
fi
if [ -n "$KEY_VAULT_ADMIN_PRINCIPAL_ID" ]; then
  PARAMS_ARRAY+=(--parameters "keyVaultAdminPrincipalId=$KEY_VAULT_ADMIN_PRINCIPAL_ID")
fi

az stack sub validate \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  "${PARAMS_ARRAY[@]}"
