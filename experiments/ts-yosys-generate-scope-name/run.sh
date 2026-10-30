#!/usr/bin/env bash
set -euo pipefail

image=geek-eda:0.2
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

printf '%s\n' '$ docker run --rm geek-eda:0.2 yosys -V'
docker run --rm "$image" yosys -V

run_case() {
    local name=$1
    local expected=$2
    local top=${name}_top
    local log=/out/${name}.log
    local netlist=/out/${name}_out.v

    printf '\n=== %s generate scope ===\n' "$name"
    printf '%s\n' '$ yosys -p "read_verilog -sv; hierarchy; proc; select -list; write_verilog; synth; stat"'
    docker run --rm \
        -v "$root:/work" -v "$out:/out" -w /work "$image" \
        yosys -Q -T -l "$log" -p \
        "read_verilog -sv ${name}.v; hierarchy -check -top ${top}; proc; select -list ${top}/w:*; select -list ${top}/c:*; write_verilog -noattr ${netlist}; synth -top ${top}; stat" \
        >/dev/null

    grep -E '^(Generating RTLIL|Successfully finished|Top module:|Executing SELECT|'"${top}"'/|End of script|=== '"${top}"' ===|   Number of cells:|     \$_NOT_)' "$out/${name}.log" || true
    printf '%s\n' '-- generated scope names in write_verilog output --'
    grep -E 'genblk|decode_scope' "$out/${name}_out.v"

    local warnings
    warnings=$(grep -c 'Warning:' "$out/${name}.log" || true)
    printf '%s_warning_count=%s\n' "$name" "$warnings"
    test "$warnings" -eq 0
    grep -q "$expected" "$out/${name}.log"
    grep -q "$expected" "$out/${name}_out.v"
}

run_case auto genblk1
run_case named decode_scope
printf '\nresult=auto genblk1 and named decode_scope observed; both synth passed with zero warnings\n'
