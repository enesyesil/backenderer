#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/validate_config.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASS_APP_DIR="$TMP_DIR/app"
mkdir -p "$PASS_APP_DIR"
touch "$PASS_APP_DIR/Dockerfile"

run_pass() {
  local name="$1"
  local config_path="$2"

  BACKENDERER_APP_DIR="$PASS_APP_DIR" "$SCRIPT" "$config_path" >/dev/null
  echo "[validate_config] pass: $name"
}

run_fail() {
  local name="$1"
  local config_path="$2"

  if BACKENDERER_APP_DIR="$PASS_APP_DIR" "$SCRIPT" "$config_path" >/dev/null 2>&1; then
    echo "[validate_config] expected failure: $name" >&2
    exit 1
  fi

  echo "[validate_config] fail as expected: $name"
}

cat >"$TMP_DIR/valid-image.yaml" <<'EOF'
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: _
  image_uri: nginx:1.27-alpine
EOF

cat >"$TMP_DIR/valid-source.yaml" <<'EOF'
deploy:
  mode: source
  app_name: hello-web
  container_port: 8080
  health_path: /health
  server_name: hello.example.com
EOF

cat >"$TMP_DIR/invalid-server-name.yaml" <<'EOF'
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: bad host
  image_uri: nginx:1.27-alpine
EOF

cat >"$TMP_DIR/missing-image-uri.yaml" <<'EOF'
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: /
  server_name: hello.example.com
EOF

cat >"$TMP_DIR/invalid-port.yaml" <<'EOF'
deploy:
  mode: image
  app_name: hello-web
  container_port: 70000
  health_path: /
  server_name: hello.example.com
  image_uri: nginx:1.27-alpine
EOF

cat >"$TMP_DIR/invalid-health-path.yaml" <<'EOF'
deploy:
  mode: image
  app_name: hello-web
  container_port: 80
  health_path: health
  server_name: hello.example.com
  image_uri: nginx:1.27-alpine
EOF

run_pass "valid image mode" "$TMP_DIR/valid-image.yaml"
run_pass "valid source mode" "$TMP_DIR/valid-source.yaml"
run_fail "invalid server name" "$TMP_DIR/invalid-server-name.yaml"
run_fail "missing image uri" "$TMP_DIR/missing-image-uri.yaml"
run_fail "invalid port" "$TMP_DIR/invalid-port.yaml"
run_fail "invalid health path" "$TMP_DIR/invalid-health-path.yaml"
