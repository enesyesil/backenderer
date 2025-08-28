#!/bin/bash -euxo pipefail

# -------- Base packages / Docker / Nginx --------
if command -v dnf >/dev/null 2>&1; then
  PKG_MGR=dnf
  sudo dnf -y update
  sudo dnf -y install docker nginx
elif command -v yum >/dev/null 2>&1; then
  PKG_MGR=yum
  sudo yum -y update
  sudo yum -y install docker nginx
elif command -v apt-get >/dev/null 2>&1; then
  PKG_MGR=apt
  sudo apt-get update -y
  sudo apt-get install -y docker.io nginx
else
  echo "Unsupported OS: no dnf/yum/apt-get"; exit 1
fi

# Enable + start services
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user || true  # ubuntu images may use 'ubuntu' user; harmless if ec2-user absent
id -nG | grep -q docker || true

sudo systemctl enable nginx
sudo systemctl start nginx

# -------- Backenderer FS layout --------
sudo mkdir -p /opt/backenderer/{apps,bin,state,nginx/sites-available,nginx/sites-enabled}
sudo chmod -R 755 /opt/backenderer

# Ensure Nginx loads our per-app vhosts
sudo tee /etc/nginx/conf.d/backenderer.conf >/dev/null <<'NGX'
# Include per-app virtual hosts
include /opt/backenderer/nginx/sites-enabled/*.conf;

# Simple built-in health endpoint so CI can verify host is up
server {
    listen 80 default_server;
    server_name _;
    location /backenderer/health {
        add_header Content-Type text/plain;
        return 200 "ok\n";
    }
}
NGX

# Harden nginx a touch (no server_tokens)
if ! grep -q "^server_tokens off;" /etc/nginx/nginx.conf; then
  sudo sed -i 's|http { |http {\n    server_tokens off;\n|' /etc/nginx/nginx.conf || true
fi

sudo nginx -t
sudo systemctl reload nginx

# -------- SSM Agent (usually preinstalled on Amazon Linux 2023) --------
if ! systemctl is-enabled amazon-ssm-agent >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    sudo systemctl enable --now amazon-ssm-agent || true
  elif command -v snap >/dev/null 2>&1; then
    sudo snap install amazon-ssm-agent --classic || true
    sudo systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
  fi
fi

echo "Bootstrap complete."
