#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
REL="experiments/ts-yosys-defparam-not-supported"
TMP="$(mktemp -d "$DIR/.tmp.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP_REL="${TMP#"$ROOT/"}"

cd "$ROOT"
docker run --rm geek-eda:0.2 yosys -V

echo "== defparam hierarchical override =="
docker run --rm -v "$ROOT:/work" -w /work geek-eda:0.2 yosys -p \
  "read_verilog $REL/defparam.v; hierarchy -check -top top; proc; opt_clean; check -assert; write_json $TMP_REL/defparam.json"
defparam_result="$(node "$DIR/check-json.mjs" "$TMP/defparam.json" defparam)"

echo "== instance parameter list =="
docker run --rm -v "$ROOT:/work" -w /work geek-eda:0.2 yosys -p \
  "read_verilog $REL/fixed.v; hierarchy -check -top top; proc; opt_clean; check -assert; write_json $TMP_REL/fixed.json"
fixed_result="$(node "$DIR/check-json.mjs" "$TMP/fixed.json" fixed)"

echo "== verification summary =="
printf '%s\n' "$defparam_result" "$fixed_result"
echo "ALL CHECKS PASS"
