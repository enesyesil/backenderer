#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <deploy|infra|remove> <dev|prod>"
}

[[ "$#" -eq 2 ]] || { usage >&2; exit 2; }

WORKFLOW_KIND="$1"
ENVIRONMENT="$2"

emit() {
  printf '%s=%s\n' "$1" "$2"
}

require() {
  local name="$1"
  local value="$2"

  if [ -z "$value" ]; then
    echo "Missing required configuration: $name" >&2
    exit 1
  fi
}

case "$WORKFLOW_KIND" in
  deploy|infra|remove)
    ;;
  *)
    echo "Unsupported workflow kind: $WORKFLOW_KIND" >&2
    exit 1
    ;;
esac

case "$ENVIRONMENT" in
  dev)
    ROLE_ARN="${AWS_ROLE_ARN_DEV:-}"
    AWS_REGION_VALUE="${AWS_REGION_DEV:-}"
    AMI_ID_VALUE="${DEV_AMI_ID:-}"
    INSTANCE_TYPE_VALUE="${DEV_INSTANCE_TYPE:-t3.micro}"
    NAME_PREFIX_VALUE="${DEV_NAME_PREFIX:-backenderer}"
    TLS_MODE_VALUE="${DEV_TLS_MODE:-none}"
    ROUTE53_ZONE_ID_VALUE="${DEV_ROUTE53_ZONE_ID:-}"
    INSTANCE_PROFILE_VALUE="${DEV_INSTANCE_PROFILE:-}"
    TF_DIR_VALUE="infra/terraform/envs/dev"
    ;;
  prod)
    ROLE_ARN="${AWS_ROLE_ARN_PROD:-}"
    AWS_REGION_VALUE="${AWS_REGION_PROD:-}"
    AMI_ID_VALUE="${PROD_AMI_ID:-}"
    INSTANCE_TYPE_VALUE="${PROD_INSTANCE_TYPE:-t3.small}"
    NAME_PREFIX_VALUE="${PROD_NAME_PREFIX:-backenderer}"
    TLS_MODE_VALUE="${PROD_TLS_MODE:-alb_acm}"
    ROUTE53_ZONE_ID_VALUE="${PROD_ROUTE53_ZONE_ID:-}"
    INSTANCE_PROFILE_VALUE="${PROD_INSTANCE_PROFILE:-}"
    TF_DIR_VALUE="infra/terraform/envs/prod"
    ;;
  *)
    echo "Unsupported environment: $ENVIRONMENT" >&2
    exit 1
    ;;
esac

require "ROLE_ARN" "$ROLE_ARN"
require "AWS_REGION" "$AWS_REGION_VALUE"

emit "env" "$ENVIRONMENT"
emit "role_arn" "$ROLE_ARN"
emit "aws_region" "$AWS_REGION_VALUE"

if [ "$WORKFLOW_KIND" = "deploy" ]; then
  emit "ecr_repo_name" "backenderer-apps-$ENVIRONMENT"
  exit 0
fi

require "AMI_ID" "$AMI_ID_VALUE"
require "GITHUB_OIDC_PROVIDER_ARN" "${GITHUB_OIDC_PROVIDER_ARN:-}"
require "TFSTATE_BUCKET" "${TFSTATE_BUCKET:-}"
require "TFSTATE_REGION" "${TFSTATE_REGION:-}"

emit "tf_dir" "$TF_DIR_VALUE"
emit "ami_id" "$AMI_ID_VALUE"
emit "instance_type" "$INSTANCE_TYPE_VALUE"
emit "name_prefix" "$NAME_PREFIX_VALUE"
emit "tls_mode" "$TLS_MODE_VALUE"
emit "route53_zone_id" "$ROUTE53_ZONE_ID_VALUE"
emit "instance_profile" "$INSTANCE_PROFILE_VALUE"
emit "github_oidc_provider_arn" "${GITHUB_OIDC_PROVIDER_ARN}"
emit "tfstate_bucket" "${TFSTATE_BUCKET}"
emit "tfstate_region" "${TFSTATE_REGION}"
