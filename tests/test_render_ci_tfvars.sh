#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/render_ci_tfvars.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

OUT_FILE="$TMP_DIR/ci.auto.tfvars.json"

GITHUB_REPO="owner/repo" \
OIDC_PROVIDER_ARN="arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" \
STATE_BUCKET_NAME="backenderer-tf-state" \
ENVIRONMENT="dev" \
AWS_REGION="us-east-1" \
AMI_ID="ami-1234567890abcdef0" \
HEALTH_PATH="/health" \
INSTANCE_TYPE="t3.micro" \
NAME_PREFIX="backenderer" \
TLS_MODE="none" \
ROUTE53_ZONE_ID="" \
INSTANCE_PROFILE="" \
SERVER_NAME="_" \
"$SCRIPT" "$OUT_FILE" >/dev/null

jq -e '.region == "us-east-1"' "$OUT_FILE" >/dev/null
jq -e '.env == "dev"' "$OUT_FILE" >/dev/null
jq -e '.state_bucket_name == "backenderer-tf-state"' "$OUT_FILE" >/dev/null
jq -e 'has("instance_profile") | not' "$OUT_FILE" >/dev/null

echo "[render_ci_tfvars] passed"
