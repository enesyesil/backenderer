#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <name>"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ "$#" -eq 1 ]] || { usage >&2; exit 2; }

NAME="$1"
BASE=/opt/backenderer
IDX="$BASE/apps.json"
STATE_DIR="$BASE/state"
LOCK_FILE="$STATE_DIR/apps.lock"
VHOST="$BASE/nginx/sites-enabled/${NAME}.conf"

ensure_layout() {
  sudo mkdir -p "$STATE_DIR"
  sudo chmod 0700 "$STATE_DIR"
  test -f "$IDX" || echo '{}' | sudo tee "$IDX" >/dev/null
}

remove_index_entry() {
  local tmp

  tmp=$(mktemp)
  jq --arg name "$NAME" 'del(.[$name])' "$IDX" >"$tmp"
  sudo mv "$tmp" "$IDX"
}

ensure_layout

exec 9>"$LOCK_FILE"
flock 9

sudo docker rm -f "$NAME" >/dev/null 2>&1 || true
sudo rm -f "$VHOST"
sudo nginx -t
sudo systemctl reload nginx
remove_index_entry

echo "Unregistered ${NAME}"
