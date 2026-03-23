#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_BIN="${TERRAFORM_BIN:-}"

if [ -z "$TERRAFORM_BIN" ]; then
  if command -v terraform >/dev/null 2>&1; then
    TERRAFORM_BIN="$(command -v terraform)"
  elif [ -x /opt/homebrew/bin/terraform ]; then
    TERRAFORM_BIN="/opt/homebrew/bin/terraform"
  else
    echo "[preflight] terraform binary not found; set TERRAFORM_BIN or add terraform to PATH" >&2
    exit 1
  fi
fi

echo "[preflight] validating shell syntax"
bash -n "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR"/tests/*.sh

echo "[preflight] validating deploy config"
"$ROOT_DIR/scripts/validate_config.sh" "$ROOT_DIR/backenderer.config.yaml"

echo "[preflight] validating example config"
"$ROOT_DIR/scripts/validate_config.sh" "$ROOT_DIR/examples/single-app.yaml"

echo "[preflight] running shell tests"
"$ROOT_DIR/tests/run.sh"

echo "[preflight] checking terraform formatting"
"$TERRAFORM_BIN" -chdir="$ROOT_DIR" fmt -check -recursive

echo "[preflight] validating terraform roots"
for dir in "$ROOT_DIR/bootstrap" "$ROOT_DIR/infra/terraform/envs/dev" "$ROOT_DIR/infra/terraform/envs/prod"; do
  "$TERRAFORM_BIN" -chdir="$dir" init -backend=false
  "$TERRAFORM_BIN" -chdir="$dir" validate
done

echo "[preflight] running terraform tests"
for dir in \
  "$ROOT_DIR/infra/terraform/modules/iam_github_oidc" \
  "$ROOT_DIR/infra/terraform/modules/compute_vm_docker_nginx"
do
  "$TERRAFORM_BIN" -chdir="$dir" init -backend=false
  "$TERRAFORM_BIN" -chdir="$dir" test
done

echo "[preflight] complete"
