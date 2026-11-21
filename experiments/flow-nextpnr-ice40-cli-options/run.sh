#!/usr/bin/env bash
set -euo pipefail

mkdir -p build results
rm -f build/*.asc build/*.json build/*.log build/*.txt

{
    yosys -V
    nextpnr-ice40 --version
} 2>&1 | tee build/versions.log

yosys -s synth.ys 2>&1 | tee build/yosys.log
cp top.json build/top.json

run_pnr() {
    local name="$1"
    local device="$2"
    local package="$3"
    local pcf="$4"
    local cmd=(nextpnr-ice40 "$device" --package "$package"
        --json top.json --pcf "$pcf" --asc "build/${name}.asc"
        --report "build/${name}-report.json" --freq 12 --seed 1)
    printf '$' | tee "build/${name}.log"
    printf ' %q' "${cmd[@]}" | tee -a "build/${name}.log"
    printf '\n' | tee -a "build/${name}.log"
    "${cmd[@]}" 2>&1 | tee -a "build/${name}.log"
}

run_pnr up5k --up5k sg48 up5k-sg48.pcf
run_pnr hx8k --hx8k ct256 hx8k-ct256.pcf

set +e
run_pnr bad-pin --up5k sg48 up5k-sg48-bad-pin.pcf
bad_status=$?
set -e
printf 'bad-pin exit code: %s\n' "$bad_status" | tee -a build/bad-pin.log
if [ "$bad_status" -eq 0 ]; then
    printf 'ERROR: invalid-pin control unexpectedly succeeded\n' >&2
    exit 1
fi

cp build/up5k-report.json build/hx8k-report.json results/
{
    wc -c build/top.json build/up5k.asc build/hx8k.asc
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum build/top.json build/up5k.asc build/hx8k.asc
    else
        shasum -a 256 build/top.json build/up5k.asc build/hx8k.asc
    fi
} | tee build/artifacts.txt
cp build/artifacts.txt results/artifacts.txt

for artifact in build/up5k.asc build/hx8k.asc build/up5k-report.json build/hx8k-report.json; do
    test -s "$artifact"
done
if [ -e build/bad-pin.asc ]; then
    printf 'ERROR: failed run left an ASC artifact\n' >&2
    exit 1
fi

printf 'All success-path artifacts exist; bad-pin produced no ASC.\n'
