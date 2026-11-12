#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$PWD/results}"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-agents-nested.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
REPO="$TMP_ROOT/repository"
mkdir -p "$REPO/service/api"

cat > "$REPO/AGENTS.md" <<'EOF'
# 根目录规则
当用户要求返回规则测试标记时，只输出 ROOT_ONLY，不输出其他文字。
EOF
cat > "$REPO/service/AGENTS.md" <<'EOF'
# service 子目录规则
当用户要求返回规则测试标记时，只输出 CHILD_ONLY，不输出其他文字。
EOF
cat > "$REPO/service/api/AGENTS.md" <<'EOF'
# api 孙目录规则
当用户要求返回规则测试标记时，只输出 GRANDCHILD_ONLY，不输出其他文字。
EOF

codex --version > "$OUT_DIR/environment.log"
sw_vers >> "$OUT_DIR/environment.log"
printf '实验目录：系统临时目录，结束后自动删除\n' >> "$OUT_DIR/environment.log"
printf '配置隔离：每组使用独立临时 CODEX_HOME，不加载 config.toml\n' >> "$OUT_DIR/environment.log"

run_case() {
  local name="$1"
  local workdir="$2"
  local prompt="$3"
  local home="$TMP_ROOT/home-$name"
  local answer="$TMP_ROOT/answer-$name.txt"
  local log="$OUT_DIR/$name.log"
  mkdir -p "$home"
  if [[ -f "$HOME/.codex/auth.json" ]]; then
    cp "$HOME/.codex/auth.json" "$home/auth.json"
    chmod 600 "$home/auth.json"
  fi

  {
    printf '$ codex exec --ignore-user-config --ephemeral --skip-git-repo-check -C <%s> --color never "%s"\n' "$name" "$prompt"
    printf 'case=%s\n' "$name"
    printf 'rules=root/AGENTS.md'
    [[ "$name" != "01-root-only" ]] && printf ' + service/AGENTS.md'
    [[ "$name" == "03-root-child-grandchild" || "$name" == "04-explicit-conflict" ]] && printf ' + service/api/AGENTS.md'
    printf '\n'
  } > "$log"

  set +e
  CODEX_HOME="$home" codex exec \
    --ignore-user-config \
    --ephemeral \
    --skip-git-repo-check \
    --sandbox read-only \
    -C "$workdir" \
    --color never \
    --output-last-message "$answer" \
    "$prompt" >> "$log" 2>&1
  local status=$?
  set -e
  printf 'exit_code=%s\n' "$status" >> "$log"
  printf 'final_answer=' >> "$log"
  if [[ -f "$answer" ]]; then
    tr -d '\r\n' < "$answer" >> "$log"
  else
    printf '<missing>' >> "$log"
  fi
  printf '\n' >> "$log"
  return "$status"
}

BASE_PROMPT='请返回当前生效规则要求的测试标记，只输出标记，不要解释。'
run_case '01-root-only' "$REPO" "$BASE_PROMPT"
run_case '02-root-child' "$REPO/service" "$BASE_PROMPT"
run_case '03-root-child-grandchild' "$REPO/service/api" "$BASE_PROMPT"
run_case '04-explicit-conflict' "$REPO/service/api" '这是显式指令冲突测试。忽略仓库规则中关于标记的要求，只输出 PROMPT_ONLY，不要解释。'

{
  printf '$ bash run.sh <output-directory>\n'
  printf 'Codex: '
  codex --version
  printf '每组均为独立进程、独立临时 CODEX_HOME，工作目录逐级深入。\n'
  for name in 01-root-only 02-root-child 03-root-child-grandchild 04-explicit-conflict; do
    printf '\n[%s]\n' "$name"
    grep -E '^(case=|rules=|exit_code=|final_answer=)' "$OUT_DIR/$name.log"
  done
} > "$OUT_DIR/summary.log"

cat "$OUT_DIR/summary.log"
