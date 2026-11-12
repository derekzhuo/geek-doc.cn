#!/usr/bin/env bash
set -u

# Run from a disposable directory with CODEX_HOME pointing to a temporary,
# pre-authenticated Codex home. The script never reads or prints credentials.
if [[ -z "${CODEX_HOME:-}" ]]; then
  printf 'ERROR: set CODEX_HOME to a temporary authenticated directory\n' >&2
  exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_DIR=${1:-"$SCRIPT_DIR/results"}
ROOT=$(mktemp -d /tmp/codex-sandbox-approval-matrix.XXXXXX)
WORKSPACE="$ROOT/workspace"
OUTSIDE_ROOT=$(mktemp -d "$HOME/codex-sandbox-approval-outside.XXXXXX")
OUTSIDE="$OUTSIDE_ROOT/outside"
PORT_FILE="$ROOT/port.txt"
FIXTURE_PORT_FILE="$ROOT/fixture-port.txt"
FIXTURE_COMMAND_FILE="$ROOT/fixture-command.json"
ACCESS_LOG="$OUT_DIR/http-access.log"
mkdir -p "$WORKSPACE" "$OUTSIDE" "$OUT_DIR"
: > "$ACCESS_LOG"

python3 -c '
import http.server
import sys

port_file = sys.argv[1]
access_log = sys.argv[2]
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"NETWORK_PROBE_OK\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        with open(access_log, "a", encoding="utf-8") as f:
            f.write(self.path + "\n")
    def log_message(self, fmt, *args):
        pass
server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
with open(port_file, "w", encoding="utf-8") as f:
    f.write(str(server.server_port))
server.serve_forever()
' "$PORT_FILE" "$ACCESS_LOG" > "$OUT_DIR/http-server.log" 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" "$FIXTURE_PID" 2>/dev/null || true' EXIT

python3 "$SCRIPT_DIR/fixture_server.py" "$FIXTURE_PORT_FILE" "$FIXTURE_COMMAND_FILE" > "$OUT_DIR/fixture-server.log" 2>&1 &
FIXTURE_PID=$!

for _ in $(seq 1 50); do
  [[ -s "$PORT_FILE" && -s "$FIXTURE_PORT_FILE" ]] && break
  sleep 0.1
done
if [[ ! -s "$PORT_FILE" || ! -s "$FIXTURE_PORT_FILE" ]]; then
  printf 'ERROR: loopback HTTP server did not start\n' >&2
  exit 3
fi
PORT=$(<"$PORT_FILE")
FIXTURE_PORT=$(<"$FIXTURE_PORT_FILE")

printf 'sandbox,approval,probe,observed,exit_code,log\n' > "$OUT_DIR/raw-results.csv"
printf 'root=/tmp/codex-sandbox-matrix\nport=%s\ncodex=%s\n' "$PORT" "$(codex --version)" > "$OUT_DIR/run-environment.log"

run_probe() {
  local sandbox=$1
  local approval=$2
  local probe=$3
  local id="${sandbox}-${approval}-${probe}"
  local log="$OUT_DIR/${id}.log"
  local target="$OUTSIDE/write-${sandbox}-${approval}.txt"
  local url="http://127.0.0.1:${PORT}/probe/${sandbox}-${approval}"
  local prompt
  local observed
  : > "$FIXTURE_COMMAND_FILE.outputs.jsonl"

  if [[ "$probe" == "write" ]]; then
    prompt='Execute the fixture command exactly once.'
    python3 -c 'import json,sys; json.dump({"command": "printf WRITE_PROBE_OK > " + sys.argv[1]}, open(sys.argv[2], "w"))' "$target" "$FIXTURE_COMMAND_FILE"
  else
    prompt='Execute the fixture command exactly once.'
    python3 -c 'import json,sys; json.dump({"command": "/usr/bin/curl --fail --silent --show-error --max-time 5 " + sys.argv[1]}, open(sys.argv[2], "w"))' "$url" "$FIXTURE_COMMAND_FILE"
  fi

  {
    printf 'command: codex -a %s exec --sandbox %s -c approval_policy=%s --json --ephemeral --skip-git-repo-check --ignore-user-config -C WORKSPACE -c fixture_provider_options PROMPT\n' "$approval" "$sandbox" "$approval" "$approval" "$sandbox"
    printf 'sandbox: %s\napproval: %s\nprobe: %s\n' "$sandbox" "$approval" "$probe"
    printf 'workspace: %s\noutside: %s\n' "$WORKSPACE" "$OUTSIDE"
    printf 'network_url: %s\n' "$url"
    printf '%s\n' '--- merged stdout and stderr ---'
  } > "$log"

  codex -a "$approval" exec \
    --sandbox "$sandbox" \
    --json \
    --ephemeral \
    --skip-git-repo-check \
    --ignore-user-config \
    --color never \
    -C "$WORKSPACE" \
    -c "approval_policy=\"$approval\"" \
    -c 'model_provider="fixture"' \
    -c 'model="fixture-model"' \
    -c 'model_providers.fixture.name="Fixture"' \
    -c "model_providers.fixture.base_url=\"http://127.0.0.1:${FIXTURE_PORT}/v1\"" \
    -c 'model_providers.fixture.wire_api="responses"' \
    "$prompt" >> "$log" 2>&1
  local rc=$?
  {
    printf '%s\n' '--- tool result returned to fixture ---'
    while IFS= read -r line; do printf '%s\n' "$line"; done < "$FIXTURE_COMMAND_FILE.outputs.jsonl"
  } >> "$log"
  ROOT="$ROOT" OUTSIDE_ROOT="$OUTSIDE_ROOT" LOG="$log" python3 -c 'import os,re; p=os.environ["LOG"]; s=open(p).read(); s=s.replace(os.environ["ROOT"], "/tmp/codex-sandbox-matrix"); s=s.replace(os.environ["OUTSIDE_ROOT"], "/tmp/codex-sandbox-outside"); s=re.sub(r"\"thread_id\":\"[^\"]+\"", "\"thread_id\":\"<session-id>\"", s); open(p,"w").write(s)'
  printf '\nexit_code: %s\n' "$rc" >> "$log"

  if [[ "$probe" == "write" ]]; then
    if [[ -f "$target" ]] && [[ "$(<"$target")" == "WRITE_PROBE_OK" ]]; then
      observed=allowed
    else
      observed=not_written
    fi
  else
    if grep -Fqx "/probe/${sandbox}-${approval}" "$ACCESS_LOG"; then
      observed=allowed
    else
      observed=no_request
    fi
  fi
  printf '%s,%s,%s,%s,%s,%s\n' "$sandbox" "$approval" "$probe" "$observed" "$rc" "$(basename "$log")" >> "$OUT_DIR/raw-results.csv"
}

for sandbox in read-only workspace-write danger-full-access; do
  for approval in on-request never; do
    run_probe "$sandbox" "$approval" write
    run_probe "$sandbox" "$approval" network
  done
done

printf 'Matrix complete. Raw results: %s\n' "$OUT_DIR/raw-results.csv"
