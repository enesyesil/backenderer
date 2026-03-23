#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_packages() {
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf -y update
    sudo dnf -y install docker nginx jq curl awscli amazon-ecr-credential-helper util-linux
  elif command -v yum >/dev/null 2>&1; then
    sudo yum -y update
    sudo yum -y install docker nginx jq curl awscli amazon-ecr-credential-helper util-linux
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker.io nginx jq curl awscli amazon-ecr-credential-helper util-linux
  else
    echo "Unsupported OS: no dnf/yum/apt-get" >&2
    exit 1
  fi
}

write_docker_config() {
  local tmp

  sudo mkdir -p /root/.docker
  tmp=$(mktemp)

  if [[ -f /root/.docker/config.json ]]; then
    jq '.credHelpers = (.credHelpers // {}) | .credHelpers["public.ecr.aws"] = "ecr-login"' \
      /root/.docker/config.json >"$tmp"
  else
    jq -n '{credHelpers: {"public.ecr.aws": "ecr-login"}}' >"$tmp"
  fi

  sudo install -m 0600 "$tmp" /root/.docker/config.json
  rm -f "$tmp"
}

write_backenderer_nginx_conf() {
  sudo tee /etc/nginx/conf.d/backenderer.conf >/dev/null <<'NGX'
# Include per-app virtual hosts
include /opt/backenderer/nginx/sites-enabled/*.conf;
NGX
}

install_packages

sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user || true
sudo systemctl enable --now nginx

sudo mkdir -p /opt/backenderer/nginx/sites-enabled /opt/backenderer/state
sudo chmod 0755 /opt/backenderer
sudo chmod 0755 /opt/backenderer/nginx
sudo chmod 0700 /opt/backenderer/state
test -f /opt/backenderer/apps.json || echo '{}' | sudo tee /opt/backenderer/apps.json >/dev/null

sudo install -m 0755 "$SCRIPT_DIR/register.sh" /opt/backenderer/register.sh
sudo install -m 0755 "$SCRIPT_DIR/unregister.sh" /opt/backenderer/unregister.sh

write_docker_config
write_backenderer_nginx_conf

sudo nginx -t
sudo systemctl reload nginx

if ! systemctl is-enabled amazon-ssm-agent >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    sudo systemctl enable --now amazon-ssm-agent || true
  elif command -v snap >/dev/null 2>&1; then
    sudo snap install amazon-ssm-agent --classic || true
    sudo systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
  fi
fi

sudo /opt/backenderer/register.sh --help >/dev/null
sudo /opt/backenderer/unregister.sh --help >/dev/null
