#!/usr/bin/env bash
# Usage: register.sh <name> <image> <container_port> <server_name>



set -euo pipefail


[[ "$#" -eq 4 ]] || { echo "Usage: $0 <name> <image> <container_port> <server_name>" >&2; exit 2; }
NAME="$1"; IMAGE="$2"; CPORT="$3"; SNAME="$4"


BASE=/opt/backenderer; IDX="$BASE/apps.json"; VHOST_DIR="$BASE/nginx/sites-enabled"
PORT_BASE="${PORT_BASE:-18000}"


sudo mkdir -p "$BASE" "$VHOST_DIR"
test -f "$IDX" || echo '{}' | sudo tee "$IDX" >/dev/null


HOST_PORT=$(jq -r ".[\"$NAME\"].host_port // empty" "$IDX")


if [[ -z "${HOST_PORT}" ]]; then
  HOST_PORT="$PORT_BASE"
  while ss -ltn | awk '{print $4}' | grep -q ":$HOST_PORT$"; do HOST_PORT=$((HOST_PORT+1)); done
fi


sudo docker rm -f "$NAME" >/dev/null 2>&1 || true
sudo docker run -d --restart=always --name "$NAME" -p "127.0.0.1:${HOST_PORT}:${CPORT}" "$IMAGE"


CONF="${VHOST_DIR}/${NAME}.conf"
cat <<NG | sudo tee "$CONF" >/dev/null
server {
  listen 80;
  server_name ${SNAME};
  location / {
    proxy_pass http://127.0.0.1:${HOST_PORT};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
NG


sudo nginx -t && sudo systemctl reload nginx


TMP=$(mktemp)
jq --arg n "$NAME" --arg img "$IMAGE" --arg s "$SNAME" --argjson hp "$HOST_PORT" \
  '.[$n] = {image: $img, server_name: $s, host_port: $hp}' "$IDX" | sudo tee "$TMP" >/dev/null
sudo mv "$TMP" "$IDX"


echo "Registered ${NAME} -> ${SNAME} (127.0.0.1:${HOST_PORT})"
