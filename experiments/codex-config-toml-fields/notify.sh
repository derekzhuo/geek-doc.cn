#!/usr/bin/env bash
set -euo pipefail
umask 077
: "${CODEX_HOME:?CODEX_HOME is required}"
printf '%s\n' "${@: -1}" > "$CODEX_HOME/notify-last.json"
