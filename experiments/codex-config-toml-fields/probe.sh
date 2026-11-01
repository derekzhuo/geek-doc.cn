#!/usr/bin/env bash
set -uo pipefail

# 用法：bash probe.sh [输出日志]
# 可选：PROBE_PROVIDER_CONFIG=/绝对路径/provider.toml bash probe.sh
# provider 文件只会复制到临时 CODEX_HOME，脚本不会打印它，并在退出时删除。
OUT=${1:-probe.log}
ROOT=$(mktemp -d /tmp/codex-config-probe.XXXXXX)
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/home" "$ROOT/workspace"

redact() {
  sed -E -e "s#$ROOT#<tmp>#g" -e 's/request id: [A-Za-z0-9-]+/request id: <request-id>/g' -e 's/session id: [A-Za-z0-9-]+/session id: <session-id>/g' "$1"
}

{
  printf '$ codex --version\n'
  codex --version
  printf '\n$ codex app-server generate-json-schema --out <tmp>/schema\n'
  CODEX_HOME="$ROOT/home" codex app-server generate-json-schema --out "$ROOT/schema"
  jq -r '.definitions | ["approval_policy", (.AskForApproval.oneOf[0].enum | join(" | "))], ["sandbox_mode", (.SandboxMode.enum | join(" | "))], ["web_search", (.WebSearchMode.enum | join(" | "))] | @tsv' "$ROOT/schema/codex_app_server_protocol.v2.schemas.json"

  fields=(
    'model="gpt-5.5"'
    'model_reasoning_effort="low"'
    'approval_policy="never"'
    'sandbox_mode="workspace-write"'
    'notify=["/bin/true"]'
    'history.persistence="none"'
    'tui.alternate_screen="never"'
    'web_search="live"'
  )
  for field in "${fields[@]}"; do
    report=$(CODEX_HOME="$ROOT/home" codex --strict-config -c "$field" doctor --json 2>/dev/null)
    result=$(printf '%s' "$report" | jq -r '.checks["config.load"] | if .status == "ok" then "PASS" else "FAIL " + (.details.error // .summary) end')
    printf 'strict-config %-42s %s\n' "$field" "$result"
  done

  if [[ -n "${PROBE_PROVIDER_CONFIG:-}" ]]; then
    mkdir -p "$ROOT/before-home" "$ROOT/after-home"
    cp "$PROBE_PROVIDER_CONFIG" "$ROOT/before-home/config.toml"
    chmod 600 "$ROOT/before-home/config.toml"
    printf '\n$ CODEX_HOME=<tmp>/before-home codex exec --skip-git-repo-check --color never -C <tmp>/workspace PROMPT\n'
    CODEX_HOME="$ROOT/before-home" codex exec --skip-git-repo-check --color never -C "$ROOT/workspace" 'Reply with exactly CONFIG_PROBE_OK and do not call any tool.' > "$ROOT/before.log" 2>&1
    printf 'before exit=%s\n' "$?"
    redact "$ROOT/before.log"

    node -e 'const fs=require("fs"); const src=fs.readFileSync(process.argv[1],"utf8"); const at=src.indexOf("[model_providers]"); const provider=(src.match(/^model_provider\s*=\s*"([^"]+)"/m)||[])[1]; if(at<0||!provider) throw new Error("provider config needs model_provider and [model_providers]"); const root=`model = "gpt-5.5"\nmodel_provider = "${provider}"\nmodel_reasoning_effort = "low"\napproval_policy = "never"\nsandbox_mode = "workspace-write"\nhistory.persistence = "none"\nweb_search = "live"\ntui.alternate_screen = "never"\nnotify = ["/bin/true"]\n\n`; fs.writeFileSync(process.argv[2],root+src.slice(at),{mode:0o600});' "$PROBE_PROVIDER_CONFIG" "$ROOT/after-home/config.toml"
    printf '\n$ CODEX_HOME=<tmp>/after-home codex exec --skip-git-repo-check --color never -C <tmp>/workspace PROMPT\n'
    CODEX_HOME="$ROOT/after-home" codex exec --skip-git-repo-check --color never -C "$ROOT/workspace" 'Reply with exactly CONFIG_PROBE_OK and do not call any tool.' > "$ROOT/after.log" 2>&1
    printf 'after exit=%s\n' "$?"
    redact "$ROOT/after.log"
  else
    printf '\n未提供 PROBE_PROVIDER_CONFIG；仅执行离线 schema 与严格配置检查。\n'
  fi
} > "$OUT" 2>&1
