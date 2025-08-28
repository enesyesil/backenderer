#!/usr/bin/env bash
# Usage: unregister.sh <name>
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <name>" >&2
  exit 2
fi

NAME="$1"
BASE=/opt/backenderer
IDX="$BASE/apps.json"
VHOST="/etc/nginx/conf.d/${NAME}.conf"

# Stop/remove container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^$NAME$"; then
  docker rm -f "$NAME" || true
fi

# Remove vhost if exists
[[ -f "$VHOST" ]] && rm -f "$VHOST"

# Test & reload Nginx (non-fatal if it fails)
nginx -t && systemctl reload nginx || true

# Update index
if [[ -f "$IDX" ]]; then
  TMP="$(mktemp)"
  jq "del(.\"$NAME\")" "$IDX" > "$TMP" || echo '{}' > "$TMP"
  mv "$TMP" "$IDX"
fi

echo "Unregistered ${NAME}"
