#!/usr/bin/env bash
#
# mon-validate-stack.sh
# Location: code/pipelines/monitoring/
#
# Validates the monitoring deployment stack at subscription scope.
# Validates subscription ID and runs az stack sub validate.
#
# Usage:
#   bash mon-validate-stack.sh \
#     <monitoringSubscriptionId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <actionOnUnmanage> \
#     <projectName> \
#     <workloadAlias> \
#     <environment> \
#     <locationCode> \
#     <instanceNumber> \
#     <location> \
#     <dataRetention> \
#     <dailyQuotaGb> \
#     <owner> \
#     <managedBy> \
#     <actionGroupEmails> \
#     <actionGroupSmsNumbers>
#
# Exit codes:
#   0 - Validation succeeded
#   1 - Validation failed

set -euo pipefail

# Parameters
MONITORING_SUBSCRIPTION_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ACTION_ON_UNMANAGE="${7:-}"
PROJECT_NAME="${8:-}"
WORKLOAD_ALIAS="${9:-}"
ENVIRONMENT="${10:-}"
LOCATION_CODE="${11:-}"
INSTANCE_NUMBER="${12:-}"
LOCATION="${13:-}"
DATA_RETENTION="${14:-}"
DAILY_QUOTA_GB="${15:-}"
OWNER="${16:-}"
MANAGED_BY="${17:-}"
ACTION_GROUP_EMAILS="${18:-}"
ACTION_GROUP_SMS_NUMBERS="${19:-}"

# Validate that monitoringSubscriptionId is set
if [ -z "$MONITORING_SUBSCRIPTION_ID" ]; then
  echo "##[error]monitoringSubscriptionId is not set in the monitoring-variables variable group."
  echo "Please set the subscription ID in the variable group before running this pipeline."
  exit 1
fi
echo "✓ Monitoring subscription ID: ${MONITORING_SUBSCRIPTION_ID}"

# Build parameter overrides for pipeline parameters
# Note: Don't use quotes around values - they become part of the value
PARAMS=""
if [ -n "$WORKLOAD_ALIAS" ]; then
  PARAMS="$PARAMS --parameters workloadAlias=$WORKLOAD_ALIAS"
fi
if [ -n "$ENVIRONMENT" ]; then
  PARAMS="$PARAMS --parameters environment=$ENVIRONMENT"
fi
if [ -n "$LOCATION_CODE" ]; then
  PARAMS="$PARAMS --parameters locationCode=$LOCATION_CODE"
fi
if [ -n "$INSTANCE_NUMBER" ]; then
  PARAMS="$PARAMS --parameters instanceNumber=$INSTANCE_NUMBER"
fi
if [ -n "$LOCATION" ]; then
  PARAMS="$PARAMS --parameters location=$LOCATION"
fi
if [ -n "$DATA_RETENTION" ]; then
  PARAMS="$PARAMS --parameters dataRetention=$DATA_RETENTION"
fi
if [ -n "$DAILY_QUOTA_GB" ]; then
  PARAMS="$PARAMS --parameters dailyQuotaGb=$DAILY_QUOTA_GB"
fi
if [ -n "$OWNER" ]; then
  PARAMS="$PARAMS --parameters owner=$OWNER"
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS="$PARAMS --parameters managedBy=$MANAGED_BY"
fi

# Convert comma-separated email list from variable group to JSON array for Bicep
# Format: "email1@example.com,email2@example.com" -> JSON array of receiver objects
EMAIL_RECEIVERS="[]"
if [ -n "$ACTION_GROUP_EMAILS" ]; then
  EMAIL_RECEIVERS="["
  IFS=',' read -ra EMAILS <<< "$ACTION_GROUP_EMAILS"
  FIRST=true
  for email in "${EMAILS[@]}"; do
    email=$(echo "$email" | xargs)  # Trim whitespace
    if [ -n "$email" ]; then
      if [ "$FIRST" = true ]; then
        FIRST=false
      else
        EMAIL_RECEIVERS+=","
      fi
      EMAIL_RECEIVERS+="{\"name\":\"${email%%@*}\",\"emailAddress\":\"${email}\",\"useCommonAlertSchema\":true}"
    fi
  done
  EMAIL_RECEIVERS+="]"
fi

# Convert comma-separated SMS list from variable group to JSON array for Bicep
# Format: "1:5551234567,1:5559876543" -> JSON array of SMS receiver objects
SMS_RECEIVERS="[]"
if [ -n "$ACTION_GROUP_SMS_NUMBERS" ]; then
  SMS_RECEIVERS="["
  IFS=',' read -ra SMS_LIST <<< "$ACTION_GROUP_SMS_NUMBERS"
  FIRST=true
  for sms in "${SMS_LIST[@]}"; do
    sms=$(echo "$sms" | xargs)  # Trim whitespace
    if [ -n "$sms" ]; then
      IFS=':' read -r country phone <<< "$sms"
      if [ -n "$country" ] && [ -n "$phone" ]; then
        if [ "$FIRST" = true ]; then
          FIRST=false
        else
          SMS_RECEIVERS+=","
        fi
        SMS_RECEIVERS+="{\"name\":\"SMS-${phone}\",\"countryCode\":\"${country}\",\"phoneNumber\":\"${phone}\"}"
      fi
    fi
  done
  SMS_RECEIVERS+="]"
fi

# Write array values to temp files (one value per file) to avoid shell escaping issues
# When using .bicepparam files, we pass arrays as: paramName=@file (where file contains just the JSON array)
EMAIL_FILE=$(mktemp)
SMS_FILE=$(mktemp)
echo "${EMAIL_RECEIVERS}" > "$EMAIL_FILE"
echo "${SMS_RECEIVERS}" > "$SMS_FILE"

az stack sub validate \
  --name "$STACK_NAME" \
  --subscription "$MONITORING_SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --parameters projectName="$PROJECT_NAME" \
  --parameters actionGroupEmailReceivers=@"$EMAIL_FILE" \
  --parameters actionGroupSmsReceivers=@"$SMS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  $PARAMS

# Clean up temp files
rm -f "$EMAIL_FILE" "$SMS_FILE"
