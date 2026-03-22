#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/select_env.sh"

DEPLOY_OUTPUT="$(
  AWS_ROLE_ARN_DEV="arn:aws:iam::123456789012:role/dev" \
  AWS_REGION_DEV="us-east-1" \
  "$SCRIPT" deploy dev
)"

grep -q '^env=dev$' <<<"$DEPLOY_OUTPUT"
grep -q '^role_arn=arn:aws:iam::123456789012:role/dev$' <<<"$DEPLOY_OUTPUT"
grep -q '^aws_region=us-east-1$' <<<"$DEPLOY_OUTPUT"
grep -q '^ecr_repo_name=backenderer-apps-dev$' <<<"$DEPLOY_OUTPUT"

INFRA_OUTPUT="$(
  AWS_ROLE_ARN_PROD="arn:aws:iam::123456789012:role/prod" \
  AWS_REGION_PROD="ca-central-1" \
  GITHUB_OIDC_PROVIDER_ARN="arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" \
  PROD_AMI_ID="ami-1234567890abcdef0" \
  PROD_INSTANCE_TYPE="t3.small" \
  PROD_NAME_PREFIX="backenderer" \
  PROD_TLS_MODE="alb_acm" \
  PROD_ROUTE53_ZONE_ID="Z123456" \
  PROD_INSTANCE_PROFILE="backenderer-prod-profile" \
  TFSTATE_BUCKET="backenderer-tf-state" \
  TFSTATE_REGION="ca-central-1" \
  "$SCRIPT" infra prod
)"

grep -q '^tf_dir=infra/terraform/envs/prod$' <<<"$INFRA_OUTPUT"
grep -q '^ami_id=ami-1234567890abcdef0$' <<<"$INFRA_OUTPUT"
grep -q '^aws_region=ca-central-1$' <<<"$INFRA_OUTPUT"
grep -q '^tfstate_bucket=backenderer-tf-state$' <<<"$INFRA_OUTPUT"

if AWS_REGION_DEV="us-east-1" "$SCRIPT" deploy dev >/dev/null 2>&1; then
  echo "[select_env] expected missing role ARN to fail" >&2
  exit 1
fi

echo "[select_env] passed"
