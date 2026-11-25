#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="geek-eda:0.4-flow"
EXPECTED_ID="sha256:75f1c71377eb080f820431c0a207ebf284b02d6d258f4d51a6c1bd8e01056348"
ACTUAL_ID="$(docker image inspect "$IMAGE" --format '{{.Id}}')"
if [[ "$ACTUAL_ID" != "$EXPECTED_ID" ]]; then
  printf '工具镜像不匹配：期望 %s，实际 %s\n' "$EXPECTED_ID" "$ACTUAL_ID" >&2
  exit 1
fi

docker run --rm \
  --mount "type=bind,src=${ROOT},dst=/work" \
  --workdir /work \
  "$IMAGE" \
  bash ./verify.sh

printf '完整记录：%s/results/\n' "$ROOT"
