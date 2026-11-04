#!/usr/bin/env bash
# param-fsm-binary-onehot
# Same RTL FSM (bounded linear-walk controller), 3 state counts x 3 encodings.
# Step 1: iverilog proves BIN/GRAY/OH behave identically under one stimulus.
# Step 2: yosys maps each variant onto the teaching liberty, stat -> FF/cell/area.
# Step 3: OpenSTA reports worst setup slack under a fixed 10 ns clock.
set -u
IMAGE="${IMAGE:-geek-eda:0.4-flow}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
mkdir -p work

docker_run() { docker run --rm -v "$HERE":/work -w /work "$IMAGE" "$@"; }

echo "### toolchain versions"
docker_run yosys -V
echo -n "OpenSTA "; docker_run sta -version 2>&1 | tail -1
docker_run iverilog -V 2>&1 | head -1

echo
echo "### step1 behavioral equivalence (iverilog, one shared stimulus)"
docker_run iverilog -g2012 -o work/sim rtl/fsm_walker.v tb/tb_fsm_walker.v
docker_run vvp work/sim

echo
echo "### step2/3 synth + stat + STA, 3 sizes x 3 encodings"
echo "nstates,enc,ff,cells,area_nand2,slack_ns" > work/results.csv
for NS in 4 8 16; do
  for ENC in 0 1 2; do
    case "$ENC" in 0) NAME=bin;; 1) NAME=gray;; 2) NAME=oh;; esac
    TAG="${NS}_${NAME}"

    cat > work/synth_${TAG}.ys <<EOF
read_liberty -lib liberty/teaching.lib
read_verilog rtl/fsm_walker.v
chparam -set NSTATES $NS -set ENC $ENC fsm_walker
synth -nofsm -top fsm_walker
dfflibmap -liberty liberty/teaching.lib
abc -liberty liberty/teaching.lib
clean
stat -liberty liberty/teaching.lib
write_verilog -noattr -noexpr work/netlist_${TAG}.v
EOF

    cat > work/sta_${TAG}.tcl <<EOF
read_liberty liberty/teaching.lib
read_verilog  work/netlist_${TAG}.v
link_design   fsm_walker
read_sdc      constraints.sdc
report_checks -path_delay max -digits 3
EOF

    echo "--- yosys: NSTATES=${NS} ENC=${NAME} ---"
    docker_run yosys -s work/synth_${TAG}.ys 2>&1 | tee work/stat_${TAG}.log
    echo "--- sta: NSTATES=${NS} ENC=${NAME} ---"
    docker_run sta -no_init -no_splash -exit work/sta_${TAG}.tcl 2>&1 | tee work/sta_${TAG}.log

    FF=$(awk '/^[[:space:]]+DFF_P[[:space:]]/ {v=$2} END {print v+0}' work/stat_${TAG}.log)
    CELLS=$(awk '/Number of cells:/ {gsub(/[^0-9]/,"",$NF); v=$NF} END {print v+0}' work/stat_${TAG}.log)
    AREA=$(awk '/Chip area for (top )?module/ {v=$NF+0} END {print v}' work/stat_${TAG}.log)
    SLACK=$(awk '/slack \(MET\)|slack \(VIOLATED\)/ {v=$1+0} END {printf "%.3f", v}' work/sta_${TAG}.log)
    echo "RESULT,${NS},${NAME},ff=${FF},cells=${CELLS},area=${AREA},slack_ns=${SLACK}"
    echo "${NS},${NAME},${FF},${CELLS},${AREA},${SLACK}" >> work/results.csv
  done
done

echo
echo "### summary (clock period 10 ns, teaching liberty, same RTL)"
cat work/results.csv
