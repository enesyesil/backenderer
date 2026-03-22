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

BASE="${BACKENDERER_BASE:-/opt/backenderer}"
IDX="$BASE/apps.json"
STATE_DIR="$BASE/state"
LOCK_FILE="$STATE_DIR/apps.lock"
VHOST_DIR="$BASE/nginx/sites-enabled"
PORT_BASE="${PORT_BASE:-18000}"
HEALTH_PROBE_ATTEMPTS="${HEALTH_PROBE_ATTEMPTS:-20}"
HEALTH_PROBE_DELAY="${HEALTH_PROBE_DELAY:-2}"
CONF_PATH="${VHOST_DIR}/${NAME}.conf"
CANDIDATE_NAME="${NAME}-candidate"
PREVIOUS_NAME="${NAME}-previous"

SECONDS=0
CURRENT_PORT=""
CANDIDATE_PORT=""
HAS_VHOST_BACKUP=0
HAS_INDEX_BACKUP=0
VHOST_CHANGED=0
INDEX_CHANGED=0
NGINX_RELOADED=0
PREVIOUS_RENAMED=0
CANONICAL_REASSIGNED=0
SUCCESS=0
BACKUP_CONF="$(mktemp)"
BACKUP_IDX="$(mktemp)"

log() {
  echo "[backenderer] $*"
}

log_err() {
  echo "[backenderer] $*" >&2
}

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

current_host_port() {
  jq -r --arg name "$NAME" '.[$name].host_port // empty' "$IDX"
}

select_candidate_port() {
  local reserved_port="${1:-}"
  local candidate

  candidate="$PORT_BASE"

  while :; do
    if [[ -n "$reserved_port" && "$candidate" == "$reserved_port" ]]; then
      candidate=$((candidate + 1))
      continue
    fi

    if ss -ltn | awk '{print $4}' | grep -q ":$candidate$"; then
      candidate=$((candidate + 1))
      continue
    fi

    echo "$candidate"
    return
  done
}

backup_state() {
  if [[ -f "$CONF_PATH" ]]; then
    sudo cp "$CONF_PATH" "$BACKUP_CONF"
    HAS_VHOST_BACKUP=1
  fi

  if [[ -f "$IDX" ]]; then
    sudo cp "$IDX" "$BACKUP_IDX"
    HAS_INDEX_BACKUP=1
  fi
}

restore_vhost() {
  if [[ "$VHOST_CHANGED" -ne 1 ]]; then
    return
  fi

  if [[ "$HAS_VHOST_BACKUP" -eq 1 ]]; then
    sudo install -m 0644 "$BACKUP_CONF" "$CONF_PATH" >/dev/null 2>&1 || true
  else
    sudo rm -f "$CONF_PATH" >/dev/null 2>&1 || true
  fi

  sudo nginx -t >/dev/null 2>&1 || true
  if [[ "$NGINX_RELOADED" -eq 1 ]]; then
    sudo systemctl reload nginx >/dev/null 2>&1 || true
  fi
}

restore_index() {
  if [[ "$INDEX_CHANGED" -eq 1 && "$HAS_INDEX_BACKUP" -eq 1 ]]; then
    sudo install -m 0600 "$BACKUP_IDX" "$IDX" >/dev/null 2>&1 || true
  fi
}

restore_container_names() {
  if [[ "$CANONICAL_REASSIGNED" -eq 1 ]]; then
    sudo docker rename "$NAME" "$CANDIDATE_NAME" >/dev/null 2>&1 || true
  fi

  if [[ "$PREVIOUS_RENAMED" -eq 1 ]]; then
    sudo docker rename "$PREVIOUS_NAME" "$NAME" >/dev/null 2>&1 || true
  fi
}

cleanup_candidate() {
  sudo docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
}

cleanup_previous() {
  sudo docker rm -f "$PREVIOUS_NAME" >/dev/null 2>&1 || true
}

report_failure_state() {
  log_err "deploy_failed elapsed_seconds=$SECONDS nginx_reloaded=$NGINX_RELOADED current_port=${CURRENT_PORT:-none} candidate_port=${CANDIDATE_PORT:-none}"
  log_err "current_live_container=${NAME} previous_container=${PREVIOUS_NAME}"

  if [[ -n "$CANDIDATE_PORT" ]]; then
    sudo docker logs --tail 50 "$CANDIDATE_NAME" >&2 || true
  fi
}

on_exit() {
  local status=$?

  if [[ "$status" -ne 0 && "$SUCCESS" -ne 1 ]]; then
    report_failure_state || true
    restore_container_names || true
    restore_index || true
    restore_vhost || true
    cleanup_candidate || true
  fi

  rm -f "$BACKUP_CONF" "$BACKUP_IDX"
  exit "$status"
}

trap on_exit EXIT

write_vhost() {
  local host_port="$1"

  cat <<NG | sudo tee "$CONF_PATH" >/dev/null
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
  INDEX_CHANGED=1
}

wait_for_health() {
  local port="${1:-}"
  local probe_name="$2"
  local url
  local -a curl_cmd=(curl --retry 20 --retry-delay 2 --retry-all-errors --max-time 5 -fsS)
  local attempt

  url="http://127.0.0.1${HEALTH_PATH}"
  if [[ -n "$port" ]]; then
    url="http://127.0.0.1:${port}${HEALTH_PATH}"
  fi

  for attempt in $(seq 1 "$HEALTH_PROBE_ATTEMPTS"); do
    log "health_probe name=$probe_name attempt=$attempt elapsed_seconds=$SECONDS url=$url"

    if [[ "$SNAME" == "_" ]]; then
      if "${curl_cmd[@]}" "$url" >/dev/null; then
        return 0
      fi
    else
      if "${curl_cmd[@]}" -H "Host: ${SNAME}" "$url" >/dev/null; then
        return 0
      fi
    fi
    sleep "$HEALTH_PROBE_DELAY"
  done

  return 1
}

ensure_layout

exec 9>"$LOCK_FILE"
flock 9

backup_state
CURRENT_PORT="$(current_host_port)"
CANDIDATE_PORT="$(select_candidate_port "$CURRENT_PORT")"

log "selected_current_port=${CURRENT_PORT:-none}"
log "candidate_port=$CANDIDATE_PORT"

configure_ecr_helper "$IMAGE"
sudo docker pull "$IMAGE"
cleanup_candidate
cleanup_previous
sudo docker run -d --restart=always --name "$CANDIDATE_NAME" -p "127.0.0.1:${CANDIDATE_PORT}:${CPORT}" "$IMAGE" >/dev/null
log "candidate_container_started name=$CANDIDATE_NAME candidate_port=$CANDIDATE_PORT image=$IMAGE"

if ! wait_for_health "$CANDIDATE_PORT" "candidate-direct"; then
  echo "Application health check failed for candidate ${CANDIDATE_NAME} on ${HEALTH_PATH}" >&2
  exit 1
fi

write_vhost "$CANDIDATE_PORT"
VHOST_CHANGED=1
sudo nginx -t
sudo systemctl reload nginx
NGINX_RELOADED=1
log "vhost_cutover candidate_port=$CANDIDATE_PORT"

if ! wait_for_health "" "vhost-cutover"; then
  echo "Application health check failed for ${NAME} on ${HEALTH_PATH} after cutover" >&2
  exit 1
fi

if sudo docker rename "$NAME" "$PREVIOUS_NAME" >/dev/null 2>&1; then
  PREVIOUS_RENAMED=1
  log "previous_container_preserved name=$PREVIOUS_NAME previous_port=${CURRENT_PORT:-none}"
fi

sudo docker rename "$CANDIDATE_NAME" "$NAME"
CANONICAL_REASSIGNED=1
update_index "$CANDIDATE_PORT"

if [[ "$PREVIOUS_RENAMED" -eq 1 ]]; then
  cleanup_previous
fi

SUCCESS=1
echo "Registered ${NAME} -> ${SNAME} (127.0.0.1:${CANDIDATE_PORT})"
