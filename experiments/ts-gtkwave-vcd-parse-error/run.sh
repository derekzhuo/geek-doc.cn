#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: GTKWave 3.3.116 + Xvfb + Icarus Verilog 12.0 / geek-eda:0.2'
rm -rf build
mkdir build

printf '%s\n' '--- toolchain ---'
dpkg-query -W -f='${Package} ${Version}\n' gtkwave
iverilog -V 2>&1 | head -n 1

printf '%s\n' '--- generate control and no-signal VCD ---'
iverilog -g2012 -o build/good.vvp tb.v
vvp build/good.vvp
iverilog -g2012 -o build/empty.vvp empty.v
vvp build/empty.vvp

# All malformed files are deterministic derivatives of the simulator output.
head -n 13 build/good.vcd > build/truncated.vcd
sed 's/\$scope module tb \$end/\$scope module tb/' build/good.vcd > build/bad-header.vcd
cp build/good.vcd build/bad-time.vcd
printf '#not_a_time\n0!\n' >> build/bad-time.vcd
sed 's/\$var reg 1 ! clk \$end/\$var reg 1 ! \$end/' build/good.vcd > build/bad-definition.vcd

check_vcd() {
    name="$1"
    printf '\n--- parse %s ---\n' "$name"
    printf '$ xvfb-run -a gtkwave -x -f build/%s.vcd\n' "$name"
    xvfb-run -a gtkwave -x -f "build/$name.vcd" 2>&1
    rc=$?
    printf 'exit=%s\n' "$rc"
}

check_vcd good
check_vcd truncated
check_vcd bad-header
check_vcd bad-time
check_vcd bad-definition
check_vcd empty

printf '%s\n' '--- repair header structure and parse again ---'
sed 's/\$scope module tb/\$scope module tb \$end/' build/bad-header.vcd > build/repaired-header.vcd
check_vcd repaired-header
