#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="${1:-backenderer.config.yaml}"
APP_DIR="${BACKENDERER_APP_DIR:-app}"
SERVER_NAME_PATTERN='^_$|^(\*\.)?[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$'

json="$("$SCRIPT_DIR/read_config_json.sh" "$CONFIG_PATH")"

mode="$(jq -r '.mode // ""' <<<"$json")"
app_name="$(jq -r '.app_name // ""' <<<"$json")"
app_port="$(jq -r '.app_port // ""' <<<"$json")"
server_name="$(jq -r '.server_name // ""' <<<"$json")"
image_uri="$(jq -r '.image_uri // ""' <<<"$json")"
health_path="$(jq -r '.health_path // ""' <<<"$json")"

[[ "$app_name" =~ ^[a-z0-9-]+$ ]] || {
  echo "deploy.app_name must match ^[a-z0-9-]+$" >&2
  exit 1
}

[[ "$app_port" =~ ^[0-9]+$ ]] || {
  echo "deploy.container_port must be numeric" >&2
  exit 1
}

[ "$app_port" -ge 1 ] && [ "$app_port" -le 65535 ] || {
  echo "deploy.container_port must be between 1 and 65535" >&2
  exit 1
}

printf '%s' "$server_name" | grep -Eq "$SERVER_NAME_PATTERN" || {
  echo "deploy.server_name must be '_' or a single hostname/wildcard hostname without spaces" >&2
  exit 1
}

[[ "$health_path" == /* ]] || {
  echo "deploy.health_path must start with /" >&2
  exit 1
}

case "$mode" in
  source)
    test -f "$APP_DIR/Dockerfile" || {
      echo "mode=source requires $APP_DIR/Dockerfile" >&2
      exit 1
    }
    ;;
  image)
    test -n "$image_uri" || {
      echo "mode=image requires deploy.image_uri" >&2
      exit 1
    }
    ;;
  *)
    echo "Unsupported deploy.mode: $mode" >&2
    exit 1
    ;;
esac

echo "Validated deploy config: mode=$mode app_name=$app_name"
