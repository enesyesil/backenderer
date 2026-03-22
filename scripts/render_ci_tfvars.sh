#!/usr/bin/env bash
set -euo pipefail

OUT_PATH="${1:-ci.auto.tfvars.json}"

require() {
  local name="$1"
  local value="$2"

  if [ -z "$value" ]; then
    echo "Missing required render input: $name" >&2
    exit 1
  fi
}

require "GITHUB_REPO" "${GITHUB_REPO:-}"
require "OIDC_PROVIDER_ARN" "${OIDC_PROVIDER_ARN:-}"
require "STATE_BUCKET_NAME" "${STATE_BUCKET_NAME:-}"
require "ENVIRONMENT" "${ENVIRONMENT:-}"
require "AWS_REGION" "${AWS_REGION:-}"
require "AMI_ID" "${AMI_ID:-}"
require "HEALTH_PATH" "${HEALTH_PATH:-}"
require "INSTANCE_TYPE" "${INSTANCE_TYPE:-}"
require "NAME_PREFIX" "${NAME_PREFIX:-}"
require "TLS_MODE" "${TLS_MODE:-}"
require "SERVER_NAME" "${SERVER_NAME:-}"

jq -n \
  --arg github_repo "${GITHUB_REPO}" \
  --arg oidc_provider_arn "${OIDC_PROVIDER_ARN}" \
  --arg state_bucket_name "${STATE_BUCKET_NAME}" \
  --arg env "${ENVIRONMENT}" \
  --arg region "${AWS_REGION}" \
  --arg ami_id "${AMI_ID}" \
  --arg health_path "${HEALTH_PATH}" \
  --arg instance_type "${INSTANCE_TYPE}" \
  --arg name_prefix "${NAME_PREFIX}" \
  --arg tls_mode "${TLS_MODE}" \
  --arg route53_zone_id "${ROUTE53_ZONE_ID:-}" \
  --arg instance_profile "${INSTANCE_PROFILE:-}" \
  --arg server_name "${SERVER_NAME}" \
  '{
    github_repo: $github_repo,
    oidc_provider_arn: $oidc_provider_arn,
    state_bucket_name: $state_bucket_name,
    env: $env,
    region: $region,
    ami_id: $ami_id,
    health_path: $health_path,
    instance_type: $instance_type,
    name_prefix: $name_prefix,
    tls_mode: $tls_mode,
    route53_zone_id: $route53_zone_id,
    server_name: $server_name
  } + (if $instance_profile != "" then {instance_profile: $instance_profile} else {} end)' >"$OUT_PATH"

jq -e --arg expected_region "${AWS_REGION}" '.region == $expected_region' "$OUT_PATH" >/dev/null
echo "Rendered Terraform variables to $OUT_PATH"
