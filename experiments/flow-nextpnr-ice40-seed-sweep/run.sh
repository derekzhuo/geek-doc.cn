#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

if [[ "${1:-}" != "--inside" ]]; then
    docker run --rm -v "$PWD:/work" -w /work geek-eda:0.4-flow bash run.sh --inside
    exit 0
fi

mkdir -p build results
{
    yosys -V
    nextpnr-ice40 --version
    python3 --version
} > results/tool-versions.txt 2>&1

yosys -s synth.ys > results/yosys-synth.log 2>&1
sha256sum build/top.json > results/top-json.sha256
json_before=$(sha256sum build/top.json | cut -d' ' -f1)

for seed in 0 1 2 3 4; do
    log="results/nextpnr-seed-${seed}.log"
    asc="results/top-seed-${seed}.asc"
    rm -f "$asc"
    set +e
    (
        printf '%s\n' "$ nextpnr-ice40 --hx1k --package tq144 --json build/top.json --pcf top.pcf --freq 50 --seed ${seed} --asc ${asc}"
        nextpnr-ice40 --hx1k --package tq144 \
            --json build/top.json --pcf top.pcf --freq 50 \
            --seed "$seed" --asc "$asc"
        status=$?
        printf 'nextpnr exit code: %s\n' "$status"
        exit "$status"
    ) > "$log" 2>&1
    status=$?
    set -e
    if [[ $status -ne 0 ]]; then
        printf 'seed %s failed with exit code %s\n' "$seed" "$status" >&2
    elif [[ ! -s "$asc" ]]; then
        printf 'seed %s returned success but ASC is missing or empty\n' "$seed" >&2
        exit 1
    fi
done

json_after=$(sha256sum build/top.json | cut -d' ' -f1)
if [[ "$json_before" != "$json_after" ]]; then
    printf 'JSON changed during seed sweep\n' >&2
    exit 1
fi

python3 scripts/summarize.py --results results \
    --csv results/summary.csv --json results/summary.json
{
    printf '%s\n' '$ bash run.sh'
    cat results/tool-versions.txt
    cat results/top-json.sha256
    python3 - <<'PY'
import csv
with open('results/summary.csv', newline='', encoding='utf-8') as handle:
    rows = list(csv.DictReader(handle))
print('seed place_MHz route_MHz LC arcs ripup left result asc_sha256_12')
for row in rows:
    print(f"{row['seed']:>4} {row['placement_fmax_mhz']:>9} {row['fmax_mhz']:>9} "
          f"{row['lc_used']:>2} {row['routing_arcs']:>4} {row['ripup_arcs']:>5} "
          f"{row['remaining_arcs']:>4} {row['timing_result']:>6} {row['asc_sha256'][:12]}")
PY
    printf 'json_unchanged=PASS\n'
} > results/summary.log
cat results/summary.log
