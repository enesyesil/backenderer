#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <name> <image> <container_port> <server_name> <health_path>"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ "$#" -eq 5 ]] || { usage >&2; exit 2; }

NAME="$1"
IMAGE="$2"
CPORT="$3"
SNAME="$4"
HEALTH_PATH="$5"

BASE=/opt/backenderer
IDX="$BASE/apps.json"
STATE_DIR="$BASE/state"
LOCK_FILE="$STATE_DIR/apps.lock"
VHOST_DIR="$BASE/nginx/sites-enabled"
PORT_BASE="${PORT_BASE:-18000}"

ensure_layout() {
  sudo mkdir -p "$STATE_DIR" "$VHOST_DIR"
  sudo chmod 0700 "$STATE_DIR"
  test -f "$IDX" || echo '{}' | sudo tee "$IDX" >/dev/null
}

configure_ecr_helper() {
  local image="$1"
  local registry
  local tmp

  registry="${image%%/*}"

  case "$registry" in
    *.dkr.ecr.*.amazonaws.com|public.ecr.aws)
      sudo mkdir -p /root/.docker
      tmp=$(mktemp)
      if [[ -f /root/.docker/config.json ]]; then
        jq --arg registry "$registry" \
          '.credHelpers = (.credHelpers // {}) | .credHelpers[$registry] = "ecr-login"' \
          /root/.docker/config.json >"$tmp"
      else
        jq -n --arg registry "$registry" \
          '{credHelpers: {($registry): "ecr-login"}}' >"$tmp"
      fi
      sudo install -m 0600 "$tmp" /root/.docker/config.json
      rm -f "$tmp"
      ;;
  esac
}

select_host_port() {
  local existing_port
  local candidate

  existing_port=$(jq -r --arg name "$NAME" '.[$name].host_port // empty' "$IDX")
  if [[ -n "$existing_port" ]]; then
    echo "$existing_port"
    return
  fi

  candidate="$PORT_BASE"
  while ss -ltn | awk '{print $4}' | grep -q ":$candidate$"; do
    candidate=$((candidate + 1))
  done

  echo "$candidate"
}

write_vhost() {
  local host_port="$1"
  local conf_path="${VHOST_DIR}/${NAME}.conf"

  cat <<NG | sudo tee "$conf_path" >/dev/null
server {
  listen 80;
  server_name ${SNAME};

  location / {
    proxy_pass http://127.0.0.1:${host_port};
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}
NG
}

update_index() {
  local host_port="$1"
  local tmp

  tmp=$(mktemp)
  jq \
    --arg name "$NAME" \
    --arg image "$IMAGE" \
    --arg server_name "$SNAME" \
    --arg health_path "$HEALTH_PATH" \
    --argjson host_port "$host_port" \
    --argjson container_port "$CPORT" \
    '.[$name] = {
      image: $image,
      server_name: $server_name,
      health_path: $health_path,
      host_port: $host_port,
      container_port: $container_port
    }' "$IDX" >"$tmp"
  sudo mv "$tmp" "$IDX"
}

wait_for_health() {
  local url="http://127.0.0.1${HEALTH_PATH}"
  local -a curl_cmd=(curl --retry 20 --retry-delay 2 --retry-all-errors --max-time 5 -fsS)
  local attempt

  for attempt in $(seq 1 20); do
    if [[ "$SNAME" == "_" ]]; then
      if "${curl_cmd[@]}" "$url" >/dev/null; then
        return 0
      fi
    else
      if "${curl_cmd[@]}" -H "Host: ${SNAME}" "$url" >/dev/null; then
        return 0
      fi
    fi
    sleep 2
  done

  return 1
}

ensure_layout

exec 9>"$LOCK_FILE"
flock 9

HOST_PORT="$(select_host_port)"

configure_ecr_helper "$IMAGE"
sudo docker pull "$IMAGE"
sudo docker rm -f "$NAME" >/dev/null 2>&1 || true
sudo docker run -d --restart=always --name "$NAME" -p "127.0.0.1:${HOST_PORT}:${CPORT}" "$IMAGE" >/dev/null

write_vhost "$HOST_PORT"
sudo nginx -t
sudo systemctl reload nginx
update_index "$HOST_PORT"

if ! wait_for_health; then
  sudo docker logs --tail 50 "$NAME" >&2 || true
  echo "Application health check failed for ${NAME} on ${HEALTH_PATH}" >&2
  exit 1
fi

echo "Registered ${NAME} -> ${SNAME} (127.0.0.1:${HOST_PORT})"
