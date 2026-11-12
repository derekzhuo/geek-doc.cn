#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/codex-mcp-setup-practice}"
OUT_DIR="${OUT_DIR:-$ROOT/output}"
SERVER="$ROOT/server.mjs"
mkdir -p "$WORK_DIR/workspace" "$WORK_DIR/outside" "$WORK_DIR/codex-home" "$OUT_DIR"
chmod 700 "$WORK_DIR/codex-home"
printf 'MCP_READ_OK: hello from the allowed workspace.\n' > "$WORK_DIR/workspace/hello.txt"
printf 'This file is deliberately outside the allowed directory.\n' > "$WORK_DIR/outside/secret.txt"

# Reuse provider settings and an existing login only inside the disposable home.
# Never print either file; MCP definitions below replace the temporary config.toml.
if [[ -f "${CONFIG_SOURCE:-$HOME/.codex/config.toml}" ]]; then
  cp "${CONFIG_SOURCE:-$HOME/.codex/config.toml}" "$WORK_DIR/codex-home/config.toml"
fi
if [[ -f "${AUTH_SOURCE:-$HOME/.codex/auth.json}" ]]; then
  cp "${AUTH_SOURCE:-$HOME/.codex/auth.json}" "$WORK_DIR/codex-home/auth.json"
  chmod 600 "$WORK_DIR/codex-home/auth.json"
fi
export CODEX_HOME="$WORK_DIR/codex-home"

{
  printf '$ codex --version\n'
  codex --version
  printf '\n$ node --version\n'
  node --version
  printf '\n$ codex mcp --help\n'
  codex mcp --help
} > "$OUT_DIR/00-version-help.log" 2>&1

codex mcp remove filesystem >/dev/null 2>&1 || true
codex mcp remove broken >/dev/null 2>&1 || true
codex mcp remove polluted >/dev/null 2>&1 || true
{
  printf '$ codex mcp add filesystem -- node server.mjs /tmp/codex-mcp-setup-practice/workspace\n'
  codex mcp add filesystem -- node "$SERVER" "$WORK_DIR/workspace"
  printf '\n$ codex mcp get filesystem\n'
  codex mcp get filesystem
  printf '\n$ codex mcp list\n'
  codex mcp list
} > "$OUT_DIR/01-config.log" 2>&1

PROMPT_OK="Use only the filesystem MCP read_text_file tool to read $WORK_DIR/workspace/hello.txt. Do not use shell. Reply with the exact file content."
{
  printf '$ codex exec --json --ephemeral --skip-git-repo-check -s read-only\n'
  codex exec --json --ephemeral --skip-git-repo-check -s read-only -C "$WORK_DIR/workspace" "$PROMPT_OK"
  printf '\nnormal_case_exit=%s\n' "$?"
} > "$OUT_DIR/02-normal-call.log" 2>&1

PROMPT_OUTSIDE="Use only the filesystem MCP read_text_file tool to read $WORK_DIR/outside/secret.txt. Do not use shell or any fallback. Report the tool error exactly."
{
  printf '$ codex exec --json --ephemeral --skip-git-repo-check -s read-only (outside path)\n'
  codex exec --json --ephemeral --skip-git-repo-check -s read-only -C "$WORK_DIR/workspace" "$PROMPT_OUTSIDE"
  printf '\noutside_case_exit=%s\n' "$?"
} > "$OUT_DIR/03-outside-path.log" 2>&1

codex mcp remove filesystem >/dev/null 2>&1 || true
codex mcp remove broken >/dev/null 2>&1 || true
codex mcp remove polluted >/dev/null 2>&1 || true
{
  printf '$ codex mcp add broken -- node /tmp/codex-mcp-setup-practice/no-such-server.mjs\n'
  codex mcp add broken -- node "$WORK_DIR/no-such-server.mjs"
  printf '\n$ codex exec --json --ephemeral --skip-git-repo-check -s read-only (missing server)\n'
  codex exec --json --ephemeral --skip-git-repo-check -s read-only -C "$WORK_DIR/workspace" 'Use only the broken MCP server. Do not use shell. List its tools.'
  printf '\nmissing_case_exit=%s\n' "$?"
} > "$OUT_DIR/04-missing-command.log" 2>&1

codex mcp remove filesystem >/dev/null 2>&1 || true
codex mcp remove broken >/dev/null 2>&1 || true
codex mcp remove polluted >/dev/null 2>&1 || true
{
  printf '$ MCP_STDIO_POLLUTE=1 codex mcp add polluted -- node server.mjs workspace\n'
  codex mcp add polluted --env MCP_STDIO_POLLUTE=1 -- node "$SERVER" "$WORK_DIR/workspace"
  printf '\n$ codex exec --json --ephemeral --skip-git-repo-check -s read-only (stdio pollution)\n'
  codex exec --json --ephemeral --skip-git-repo-check -s read-only -C "$WORK_DIR/workspace" 'Use only the polluted MCP server. Do not use shell. List its tools.'
  printf '\npolluted_case_exit=%s\n' "$?"
} > "$OUT_DIR/05-stdio-pollution.log" 2>&1

printf 'Experiment logs written to %s\n' "$OUT_DIR"
