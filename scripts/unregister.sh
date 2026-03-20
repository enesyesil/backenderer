#!/usr/bin/env bash
set -euo pipefail
[[ "$#" -eq 1 ]] || { echo "Usage: $0 <name>" >&2; exit 2; }

NAME="$1"; BASE=/opt/backenderer; IDX="$BASE/apps.json"; VHOST="$BASE/nginx/sites-enabled/${NAME}.conf"


sudo docker rm -f "$NAME" >/dev/null 2>&1 || true

sudo rm -f "$VHOST"

sudo nginx -t && sudo systemctl reload nginx || true

if [[ -f "$IDX" ]]; then TMP=$(mktemp); jq "del(.\"$NAME\")" "$IDX" | sudo tee "$TMP" >/dev/null && sudo mv "$TMP" "$IDX"; fi



echo "Unregistered ${NAME}"
