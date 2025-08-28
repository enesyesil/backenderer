#!/usr/bin/env bash
# Usage: register.sh <name> <image> <container_port> <server_name>
# Idempotent: reuses existing host_port for <name> if present; safe rollback on Nginx error.
set -euo pipefail

if [[ "$#" -ne 4 ]]; then
  echo "Usage: $0 <name> <image> <container_port> <server_name>" >&2
  exit 2
fi

NAME="$1"; IMAGE="$2"; CPORT="$3"; SNAME="$4"

BASE=/opt/backenderer
IDX="$BASE/apps.json"
VHOST_DIR=/etc/nginx/conf.d
PORT_BASE="${PORT_BASE:-18000}"
MAX_PORT="${MAX_PORT:-20000}"   # safety cap

mkdir -p "$BASE" "$VHOST_DIR"
[[ -f "$IDX" ]] || echo '{}' > "$IDX"

# Validate inputs
if ! [[ "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "Error: name must match ^[a-z0-9-]+$" >&2; exit 3
fi
if ! [[ "$CPORT" =~ ^[0-9]+$ ]] || (( CPORT < 1 || CPORT > 65535 )); then
  echo "Error: container_port must be 1-65535" >&2; exit 3
fi
if [[ -z "$SNAME" ]]; then
  echo "Error: server_name cannot be empty" >&2; exit 3
fi

# Ensure unique server_name across apps
if jq -e --arg s "$SNAME" 'to_entries | any(.value.server_name == $s and .key != env.NAME)' "$IDX" >/dev/null; then
  echo "Error: server_name '$SNAME' already in use by another app" >&2
  exit 4
fi

# Allocate/reuse host port
HOST_PORT="$(jq -r --arg n "$NAME" '.[$n].host_port // "null"' "$IDX")"
if [[ "$HOST_PORT" == "null" ]]; then
  HOST_PORT="$PORT_BASE"
  # gather all used host ports (apps.json + listening sockets)
  USED="$(jq -r '.[]?.host_port' "$IDX" | tr '\n' ' ' || true)"
  while :
  do
    # not already allocated?
    if [[ " $USED " != *" $HOST_PORT "* ]] && ! ss -ltn | awk '{print $4}' | grep -q ":${HOST_PORT}$"; then
      break
    fi
    HOST_PORT=$((HOST_PORT+1))
    if (( HOST_PORT > MAX_PORT )); then
      echo "Error: no free host ports available between $PORT_BASE-$MAX_PORT" >&2
      exit 5
    fi
  done
fi

# Pull and (re)run the container
docker pull "$IMAGE"
if docker ps -a --format '{{.Names}}' | grep -q "^$NAME$"; then
  docker rm -f "$NAME" || true
fi
docker run -d --restart unless-stopped --name "$NAME" -p "${HOST_PORT}:${CPORT}" "$IMAGE"

# Write Nginx vhost
CONF="${VHOST_DIR}/${NAME}.conf"
cat >"$CONF" <<CONF
server {
  listen 80;
  server_name ${SNAME};

  # Security & limits
  client_max_body_size 25m;
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  add_header Referrer-Policy strict-origin-when-cross-origin;

  # Optional basic rate-limit presets (commented by default)
  # limit_req_zone \$binary_remote_addr zone=one:10m rate=10r/s;
  # location / { limit_req zone=one burst=20 nodelay; proxy_pass http://127.0.0.1:${HOST_PORT}; }

  location / {
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass http://127.0.0.1:${HOST_PORT};
  }

  # Health
  location = /backenderer/health {
    access_log off;
    return 200 'ok';
    add_header Content-Type text/plain;
  }
}
CONF

# Test & reload, rollback on failure
if ! nginx -t; then
  echo "Nginx config test failed; rolling back container and vhost" >&2
  docker rm -f "$NAME" || true
  rm -f "$CONF"
  exit 6
fi
systemctl reload nginx

# Persist index
TMP="$(mktemp)"
jq --arg n "$NAME" --arg img "$IMAGE" --arg s "$SNAME" --argjson hp "$HOST_PORT" \
  '.[$n] = {image: $img, server_name: $s, host_port: $hp}' "$IDX" > "$TMP"
mv "$TMP" "$IDX"

echo "Registered ${NAME} -> ${SNAME} (127.0.0.1:${HOST_PORT})"
