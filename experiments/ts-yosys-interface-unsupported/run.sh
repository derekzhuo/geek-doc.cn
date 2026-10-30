#!/usr/bin/env bash
set -u

image="geek-eda:0.2"
run_yosys() {
    echo "$ docker run --rm -v \"\$PWD:/work\" -w /work $image yosys $*"
    docker run --rm -v "$PWD:/work" -w /work "$image" yosys "$@"
}

printf '# command: bash run.sh\n'
printf '# date: 2026-10-31\n'
printf '# host-toolchain: Docker geek-eda:0.2 / Yosys 0.33\n'

run_yosys -V

printf '\n=== interface/modport input ===\n'
run_yosys -p 'read_verilog -sv interface_bad.sv'
bad_status=$?
printf 'interface_exit=%s\n' "$bad_status"

printf '\n=== flattened plain ports ===\n'
run_yosys -p 'read_verilog -sv plain_ports.v; hierarchy -top counter; proc; stat'
plain_status=$?
printf 'plain_exit=%s\n' "$plain_status"

if [ "$bad_status" -ne 0 ] && [ "$plain_status" -eq 0 ]; then
    printf 'result=expected interface rejection and plain-port success\n'
    exit 0
fi

printf 'result=unexpected outcome\n'
exit 1
