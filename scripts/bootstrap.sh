#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v dnf >/dev/null 2>&1; then
  sudo dnf -y update
  sudo dnf -y install docker nginx jq
elif command -v yum >/dev/null 2>&1; then
  sudo yum -y update
  sudo yum -y install docker nginx jq
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y docker.io nginx jq
else
  echo "Unsupported OS: no dnf/yum/apt-get" >&2
  exit 1
fi

# Enable services
sudo systemctl enable --now docker
sudo systemctl enable --now nginx

# Prepare app dir
sudo mkdir -p /opt/backenderer/nginx/sites-enabled
test -f /opt/backenderer/apps.json || echo '{}' | sudo tee /opt/backenderer/apps.json >/dev/null

if [[ -f "$SCRIPT_DIR/register.sh" ]]; then
  sudo install -m 0755 "$SCRIPT_DIR/register.sh" /opt/backenderer/register.sh
fi

if [[ -f "$SCRIPT_DIR/unregister.sh" ]]; then
  sudo install -m 0755 "$SCRIPT_DIR/unregister.sh" /opt/backenderer/unregister.sh
fi

# Nginx config
cat <<'NG' | sudo tee /etc/nginx/nginx.conf >/dev/null
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;
  sendfile      on;
  keepalive_timeout 65;
  include /opt/backenderer/nginx/sites-enabled/*.conf;
  include /etc/nginx/conf.d/*.conf;
}
NG

sudo nginx -t && sudo systemctl reload nginx || true
