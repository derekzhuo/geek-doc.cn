#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    printf 'error: python3 was not found in PATH; install Python 3.8 or newer first.\n' >&2
    exit 1
fi

for script in quantize.py base_convert.py binary_add.py signed_codes.py sign_extend.py overflow_carry.py bcd_decimal.py gray_reflection.py; do
    printf '\n########## %s ##########\n' "$script"
    python3 "$script"
done

printf '\n########## self-check ##########\n'
python3 tests/test_check.py
