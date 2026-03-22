#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/register.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

setup_fixture() {
  local case_dir="$1"
  mkdir -p "$case_dir/bin" "$case_dir/state/docker" "$case_dir/base/nginx/sites-enabled" "$case_dir/base/state"

  cat >"$case_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

  cat >"$case_dir/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TEST_STATE_DIR:?}"
DOCKER_DIR="$STATE_DIR/docker"
LOG_FILE="$STATE_DIR/docker.log"
mkdir -p "$DOCKER_DIR"

record_port() {
  : >"$STATE_DIR/listening_ports"
  find "$DOCKER_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r container_dir; do
    if [ -f "$container_dir/host_port" ]; then
      cat "$container_dir/host_port" >>"$STATE_DIR/listening_ports"
      printf '\n' >>"$STATE_DIR/listening_ports"
    fi
  done
}

command="$1"
shift || true

case "$command" in
  pull)
    printf 'pull %s\n' "$1" >>"$LOG_FILE"
    ;;
  rm)
    if [ "${1:-}" = "-f" ]; then
      shift
    fi
    for name in "$@"; do
      rm -rf "$DOCKER_DIR/$name"
      printf 'rm %s\n' "$name" >>"$LOG_FILE"
    done
    record_port
    ;;
  run)
    host_port=""
    name=""
    image=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -d|--restart=always)
          shift
          ;;
        --name)
          name="$2"
          shift 2
          ;;
        -p)
          host_port="${2#127.0.0.1:}"
          host_port="${host_port%%:*}"
          shift 2
          ;;
        *)
          image="$1"
          shift
          ;;
      esac
    done
    mkdir -p "$DOCKER_DIR/$name"
    printf '%s' "$image" >"$DOCKER_DIR/$name/image"
    printf '%s' "$host_port" >"$DOCKER_DIR/$name/host_port"
    case "$image" in
      *broken*|*unhealthy*)
        printf 'false' >"$DOCKER_DIR/$name/healthy"
        ;;
      *)
        printf 'true' >"$DOCKER_DIR/$name/healthy"
        ;;
    esac
    printf 'run %s %s %s\n' "$name" "$host_port" "$image" >>"$LOG_FILE"
    record_port
    printf '%s\n' "$name"
    ;;
  logs)
    if [ "${1:-}" = "--tail" ]; then
      shift 2
    fi
    name="$1"
    if [ -f "$DOCKER_DIR/$name/image" ]; then
      printf 'logs for %s (%s)\n' "$name" "$(cat "$DOCKER_DIR/$name/image")"
    fi
    ;;
  rename)
    mv "$DOCKER_DIR/$1" "$DOCKER_DIR/$2"
    printf 'rename %s %s\n' "$1" "$2" >>"$LOG_FILE"
    ;;
  *)
    echo "unsupported docker command: $command" >&2
    exit 1
    ;;
esac
EOF

  cat >"$case_dir/bin/ss" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TEST_STATE_DIR:?}"
echo "State Recv-Q Send-Q Local Address:Port Peer Address:Port"
if [ -f "$STATE_DIR/listening_ports" ]; then
  while read -r port; do
    [ -n "$port" ] || continue
    echo "LISTEN 0 0 127.0.0.1:${port} 0.0.0.0:*"
  done <"$STATE_DIR/listening_ports"
fi
EOF

  cat >"$case_dir/bin/nginx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-t" ]; then
  exit 0
fi

echo "unsupported nginx command" >&2
exit 1
EOF

  cat >"$case_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TEST_STATE_DIR:?}"
printf 'systemctl %s %s\n' "$1" "$2" >>"$STATE_DIR/systemctl.log"
EOF

  cat >"$case_dir/bin/flock" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF

  cat >"$case_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TEST_STATE_DIR:?}"
BASE_DIR="${BACKENDERER_BASE:?}"
DOCKER_DIR="$STATE_DIR/docker"
host_header=""
url=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -H)
      host_header="$2"
      shift 2
      ;;
    --retry|--retry-delay|--max-time)
      shift 2
      ;;
    --retry-all-errors|-f|-s|-S)
      shift
      ;;
    http://*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

port="$(printf '%s' "$url" | sed -n 's#http://127\.0\.0\.1:\([0-9][0-9]*\).*#\1#p')"
path="$(printf '%s' "$url" | sed -E 's#http://127\.0\.0\.1(:[0-9]+)?##')"
[ -n "$path" ] || path="/"

if [ -z "$port" ]; then
  conf_path="$BASE_DIR/nginx/sites-enabled/hello-web.conf"
  port="$(sed -n 's#.*proxy_pass http://127.0.0.1:\([0-9][0-9]*\);#\1#p' "$conf_path" | head -n 1)"
fi

container_dir=""
for candidate_dir in "$DOCKER_DIR"/*; do
  [ -d "$candidate_dir" ] || continue
  if [ -f "$candidate_dir/host_port" ] && [ "$(cat "$candidate_dir/host_port")" = "$port" ]; then
    container_dir="$candidate_dir"
    break
  fi
done

[ -n "$container_dir" ] || exit 22
[ -f "$container_dir/healthy" ] || exit 22
[ "$(cat "$container_dir/healthy")" = "true" ] || exit 22
[ "$path" = "/" ] || [ "$path" = "/health" ] || exit 22

if [ -n "$host_header" ] && [[ "$host_header" != Host:* ]]; then
  exit 22
fi
EOF

  chmod +x "$case_dir/bin/"*
}

seed_live_app() {
  local case_dir="$1"
  local port="$2"
  local image="$3"

  mkdir -p "$case_dir/state/docker/hello-web"
  printf '%s' "$image" >"$case_dir/state/docker/hello-web/image"
  printf '%s' "$port" >"$case_dir/state/docker/hello-web/host_port"
  printf 'true' >"$case_dir/state/docker/hello-web/healthy"
  printf '%s\n' "$port" >"$case_dir/state/listening_ports"

  cat >"$case_dir/base/apps.json" <<EOF
{"hello-web":{"image":"$image","server_name":"_","health_path":"/","host_port":$port,"container_port":80}}
EOF

  cat >"$case_dir/base/nginx/sites-enabled/hello-web.conf" <<EOF
server {
  listen 80;
  server_name _;
  location / {
    proxy_pass http://127.0.0.1:${port};
  }
}
EOF
}

run_register() {
  local case_dir="$1"
  shift

  PATH="$case_dir/bin:$PATH" \
  TEST_STATE_DIR="$case_dir/state" \
  BACKENDERER_BASE="$case_dir/base" \
  PORT_BASE="18000" \
  HEALTH_PROBE_ATTEMPTS="3" \
  HEALTH_PROBE_DELAY="0" \
  "$SCRIPT" "$@"
}

SUCCESS_CASE="$TMP_DIR/success"
setup_fixture "$SUCCESS_CASE"
seed_live_app "$SUCCESS_CASE" "18000" "old-image"
mkdir -p "$SUCCESS_CASE/state/docker/hello-web-candidate"
printf '%s' "stale-image" >"$SUCCESS_CASE/state/docker/hello-web-candidate/image"
printf '%s' "18001" >"$SUCCESS_CASE/state/docker/hello-web-candidate/host_port"
printf 'true' >"$SUCCESS_CASE/state/docker/hello-web-candidate/healthy"
printf '18000\n18001\n' >"$SUCCESS_CASE/state/listening_ports"

run_register "$SUCCESS_CASE" "hello-web" "new-image" "80" "_" "/" >/dev/null

[ -d "$SUCCESS_CASE/state/docker/hello-web" ]
[ ! -d "$SUCCESS_CASE/state/docker/hello-web-candidate" ]
[ "$(jq -r '.["hello-web"].image' "$SUCCESS_CASE/base/apps.json")" = "new-image" ]
[ "$(jq -r '.["hello-web"].host_port' "$SUCCESS_CASE/base/apps.json")" = "18002" ]
grep -q 'proxy_pass http://127.0.0.1:18002;' "$SUCCESS_CASE/base/nginx/sites-enabled/hello-web.conf"

FAIL_CASE="$TMP_DIR/failure"
setup_fixture "$FAIL_CASE"
seed_live_app "$FAIL_CASE" "18000" "old-image"

if run_register "$FAIL_CASE" "hello-web" "broken-image" "80" "_" "/" >"$FAIL_CASE/stdout.log" 2>"$FAIL_CASE/stderr.log"; then
  echo "[register] expected candidate health failure" >&2
  exit 1
fi

[ -d "$FAIL_CASE/state/docker/hello-web" ]
[ ! -d "$FAIL_CASE/state/docker/hello-web-candidate" ]
[ "$(jq -r '.["hello-web"].image' "$FAIL_CASE/base/apps.json")" = "old-image" ]
[ "$(jq -r '.["hello-web"].host_port' "$FAIL_CASE/base/apps.json")" = "18000" ]
grep -q 'proxy_pass http://127.0.0.1:18000;' "$FAIL_CASE/base/nginx/sites-enabled/hello-web.conf"
grep -q 'elapsed_seconds=' "$FAIL_CASE/stderr.log"
grep -q 'nginx_reloaded=' "$FAIL_CASE/stderr.log"

echo "[register] passed"
