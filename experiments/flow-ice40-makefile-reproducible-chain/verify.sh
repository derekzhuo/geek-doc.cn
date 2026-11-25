#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
mkdir -p results
IMAGE="geek-eda:0.4-flow / image-id sha256:75f1c71377eb080f820431c0a207ebf284b02d6d258f4d51a6c1bd8e01056348"

write_header() {
    local name="$1"
    printf 'command=bash run.sh (%s)\n' "$name"
    printf 'date=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'host-toolchain=%s / linux/amd64 / Ubuntu 24.04.5 LTS\n' "$IMAGE"
    yosys -V
    nextpnr-ice40 --version 2>&1
    dpkg-query -W -f='icepack-package=fpga-icestorm ${Version}\n' fpga-icestorm
    make --version | head -n 1
    printf '%s\n' '---'
}

full_build() {
    make clean
    make --no-builtin-rules all
    make verify
    test -s build/blink.json
    test -s build/blink.asc
    test -s build/blink.bin
    sha256sum build/blink.json build/blink.asc build/blink.bin > results/full-build.sha256
    printf 'PASS: full chain produced non-empty JSON, ASC and BIN; baseline hashes saved.\n'
}

incremental_build() {
    local before after mtime_before mtime_after
    before="$(sha256sum build/blink.json build/blink.asc build/blink.bin)"
    mtime_before="$(stat -c '%n %y' build/blink.json build/blink.asc build/blink.bin)"
    make --no-builtin-rules all
    after="$(sha256sum build/blink.json build/blink.asc build/blink.bin)"
    mtime_after="$(stat -c '%n %y' build/blink.json build/blink.asc build/blink.bin)"
    printf '%s\n' '--- hashes before ---' "$before" '--- hashes after ---' "$after"
    printf '%s\n' '--- mtimes before ---' "$mtime_before" '--- mtimes after ---' "$mtime_after"
    test "$before" = "$after"
    test "$mtime_before" = "$mtime_after"
    printf 'PASS: second make ran no tool; hashes and mtimes stayed unchanged.\n'
}

clean_rebuild() {
    make clean
    test ! -e build/blink.json
    test ! -e build/blink.asc
    test ! -e build/blink.bin
    make --no-builtin-rules all
    make verify
    sha256sum -c results/full-build.sha256
    printf 'PASS: clean removed all products; rebuilt JSON, ASC and BIN match baseline hashes.\n'
}

run_case() {
    local name="$1"
    local fn="$2"
    local log="results/${name}.log"
    write_header "$name" > "$log"
    set +e
    (
        set -e
        "$fn"
    ) >> "$log" 2>&1
    local status=$?
    set -e
    printf 'exit_status=%d\n' "$status" >> "$log"
    if [[ "$status" -ne 0 ]]; then
        printf 'FAIL: %s (exit %d), see %s\n' "$name" "$status" "$log" >&2
        return "$status"
    fi
    printf '%s: PASS, exit_status=0\n' "$name"
}

run_case full-build full_build
run_case incremental incremental_build
run_case clean-rebuild clean_rebuild
printf 'ALL_PASS: full build, no-op incremental build, and clean reproducible rebuild.\n'
