#!/usr/bin/env bash
# Yosys 网表 -> OpenSTA 交接全链：综合 / 映射 / 出网表 / setup / hold
# 依赖：docker 镜像 geek-eda:0.3-sta（Yosys 0.33 + OpenSTA 2.0.17）
set -u
IMAGE="${IMAGE:-geek-eda:0.3-sta}"

docker_run() { docker run --rm -v "$PWD":/work -w /work "$IMAGE" "$@"; }

echo "### versions"
docker_run yosys -V
docker_run sta -version | grep -E '[0-9]+\.[0-9]+\.[0-9]+'

echo
echo "### step1 yosys: read/synth/flatten/dfflibmap/abc/stat/write_verilog"
docker_run yosys -s synth.ys

echo
echo "### step2 hand-off netlist netlist.v"
cat netlist.v

echo
echo "### step3 OpenSTA setup check (separate process)"
docker_run sta -no_init -no_splash -exit sta_setup.tcl

echo
echo "### step4 OpenSTA hold check (separate process)"
docker_run sta -no_init -no_splash -exit sta_hold.tcl

echo
echo "### mistake A: top module name mismatch"
printf 'read_liberty teaching.lib\nread_verilog netlist.v\nlink_design top_wrong\n' > _wrong.tcl
docker_run sta -no_init -no_splash -exit _wrong.tcl || true

echo
echo "### mistake B: dfflibmap skipped, generic \$_DFF_P_ leaks into netlist"
docker_run yosys -q -p 'read_liberty -lib teaching.lib; read_verilog rtl.v; synth -flatten -top top; abc -liberty teaching.lib; clean; write_verilog -noattr -noexpr no_dffmap.v'
grep -n '_DFF_P_' no_dffmap.v
printf 'read_liberty teaching.lib\nread_verilog no_dffmap.v\nlink_design top\nread_sdc constraints.sdc\nreport_checks -path_delay max\n' > _nodff.tcl
docker_run sta -no_init -no_splash -exit _nodff.tcl || true
rm -f _wrong.tcl _nodff.tcl no_dffmap.v
