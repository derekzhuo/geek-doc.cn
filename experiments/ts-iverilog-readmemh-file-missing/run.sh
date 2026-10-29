#!/usr/bin/env bash
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT" || exit 1

version=$(iverilog -V 2>&1)
printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s %s / %s\n' "$(uname -s)" "$(uname -r)" "${version%%$'\n'*}"

rm -rf build
mkdir build
failures=0

expect_exit() {
    label=$1
    expected=$2
    actual=$3
    printf '%s exit=%s (expected=%s)\n' "$label" "$actual" "$expected"
    if [ "$actual" -ne "$expected" ]; then
        failures=$((failures + 1))
    fi
}

printf '\n=== broken: named file does not exist ===\n'
iverilog -g2012 -s tb_readmemh -o build/broken.vvp broken/tb_readmemh.sv 2>&1
expect_exit "broken compile" 0 "$?"
vvp build/broken.vvp 2>&1
expect_exit "broken simulation" 1 "$?"

printf '\n=== fixed: launch from experiment root ===\n'
iverilog -g2012 -s tb_readmemh -o build/fixed.vvp fixed/tb_readmemh.sv 2>&1
expect_exit "fixed compile" 0 "$?"
vvp build/fixed.vvp 2>&1
expect_exit "fixed simulation" 0 "$?"

printf '\n=== wrong cwd: same fixed vvp launched from fixed/ ===\n'
(
    cd fixed || exit 1
    vvp ../build/fixed.vvp 2>&1
)
expect_exit "wrong-cwd simulation" 1 "$?"

printf '\n=== malformed: file exists but contains non-hex data ===\n'
iverilog -g2012 -s tb_readmemh -o build/malformed.vvp malformed/tb_readmemh.sv 2>&1
expect_exit "malformed compile" 0 "$?"
vvp build/malformed.vvp 2>&1
expect_exit "malformed simulation" 1 "$?"

if [ "$failures" -eq 0 ]; then
    printf '\nPASS: missing file and wrong cwd failed; fixed path passed; malformed hex was distinguished\n'
    exit 0
fi

printf '\nFAIL: %s case result(s) differed from expectation\n' "$failures"
exit 1
