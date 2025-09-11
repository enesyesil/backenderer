#!/usr/bin/env bash
set -euo pipefail

# Detect package manager
which dnf >/dev/null 2>&1 && PM=dnf || PM=apt

# Install dependencies
sudo $PM -y update
sudo $PM -y install docker nginx jq || true

# Enable services
sudo systemctl enable --now docker
sudo systemctl enable --now nginx

# Prepare app dir
sudo mkdir -p /opt/backenderer
test -f /opt/backenderer/apps.json || echo '{}' | sudo tee /opt/backenderer/apps.json >/dev/null

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
  include /etc/nginx/conf.d/*.conf;
}
NG

sudo nginx -t && sudo systemctl reload nginx || true
