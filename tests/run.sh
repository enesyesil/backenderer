#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for test_file in \
  "$TEST_DIR/test_validate_config.sh" \
  "$TEST_DIR/test_select_env.sh" \
  "$TEST_DIR/test_render_ci_tfvars.sh" \
  "$TEST_DIR/test_register.sh"
do
  echo "[tests] running $(basename "$test_file")"
  "$test_file"
done

echo "[tests] all shell tests passed"
