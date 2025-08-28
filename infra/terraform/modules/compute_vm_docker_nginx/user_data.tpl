cat > ../../modules/compute_vm_docker_nginx/user_data.tpl <<'TPL'
#!/bin/bash
set -euxo pipefail

dnf update -y
amazon-linux-extras enable nginx1
dnf install -y docker nginx unzip curl jq
systemctl enable --now docker
systemctl enable --now nginx
systemctl enable --now amazon-ssm-agent || true

mkdir -p /opt/backenderer/{conf,bin}
mkdir -p /etc/nginx/conf.d
echo '{}' > /opt/backenderer/apps.json

cat >/opt/backenderer/bin/register.sh <<'REG'
#!/usr/bin/env bash
# Usage: register.sh <name> <image> <container_port> <server_name>
set -euo pipefail
NAME="$1"; IMAGE="$2"; CPORT="$3"; SNAME="$4"
BASE=/opt/backenderer
IDX="$BASE/apps.json"
PORT_BASE=18000
jq . "$IDX" >/dev/null 2>&1 || echo '{}' > "$IDX"

# reuse or allocate host port
HOST_PORT=$(jq -r --arg n "$NAME" 'if has($n) then .[$n].host_port else null end' "$IDX")
if [[ "$HOST_PORT" == "null" || -z "$HOST_PORT" ]]; then
  HOST_PORT=$PORT_BASE
  while ss -ltn | awk '{print $4}' | grep -q ":$HOST_PORT$"; do HOST_PORT=$((HOST_PORT+1)); done
fi

docker pull "$IMAGE"
if docker ps -a --format '{{.Names}}' | grep -q "^$NAME$"; then docker rm -f "$NAME" || true; fi
docker run -d --restart unless-stopped --name "$NAME" -p "$HOST_PORT:$CPORT" "$IMAGE"

CONF="/etc/nginx/conf.d/$${NAME}.conf"
cat >"$CONF" <<CONF
server {
  listen 80;
  server_name $${SNAME};
  client_max_body_size 25m;

  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  add_header Referrer-Policy strict-origin-when-cross-origin;

  location / {
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass http://127.0.0.1:$${HOST_PORT};
  }
}
CONF

nginx -t && systemctl reload nginx || { docker rm -f "$NAME" || true; rm -f "$CONF"; exit 1; }

TMP=$(mktemp)
jq --arg n "$NAME" --arg img "$IMAGE" --arg s "$SNAME" --argjson hp "$HOST_PORT" \
  '.[$n] = {image: $img, server_name: $s, host_port: $hp}' "$IDX" > "$TMP" && mv "$TMP" "$IDX"
echo "Registered $NAME -> $${SNAME} (127.0.0.1:$${HOST_PORT})"
REG
chmod +x /opt/backenderer/bin/register.sh

cat >/opt/backenderer/bin/unregister.sh <<'UNREG'
#!/usr/bin/env bash
# Usage: unregister.sh <name>
set -euo pipefail
NAME="$1"
BASE=/opt/backenderer
IDX="$BASE/apps.json"

if docker ps -a --format '{{.Names}}' | grep -q "^$NAME$"; then docker rm -f "$NAME" || true; fi
CONF="/etc/nginx/conf.d/$${NAME}.conf"
if [[ -f "$CONF" ]]; then rm -f "$CONF"; fi
nginx -t && systemctl reload nginx || true

jq "del(.\"$NAME\")" "$IDX" > "$IDX.tmp" 2>/dev/null || echo '{}' > "$IDX.tmp"
mv "$IDX.tmp" "$IDX"
echo "Unregistered $NAME"
UNREG
chmod +x /opt/backenderer/bin/unregister.sh
TPL
