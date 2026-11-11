#!/bin/bash
# Reproduce every yosys output quoted in the abc -liberty mapping article.
set -e

echo "## yosys version:"
yosys -V

echo
echo "## cells provided by teaching library tiny.lib:"
grep -E '^  cell\(' tiny.lib

# ---- [1] gate-level stat before liberty mapping ----
echo
echo "================ [1] pre-map stat: synth done, no liberty yet ================"
cat > /tmp/pre.ys <<'EOF'
read_verilog counter.v
synth -top counter
stat
EOF
yosys -s /tmp/pre.ys 2>&1 | awk '/2.25. Printing statistics/{p=1} p' | head -24

# ---- [2] default dfflibmap + abc -liberty mapping ----
echo
echo "================ [2] map: dfflibmap + abc -liberty tiny.lib ================"
cat > /tmp/map.ys <<'EOF'
read_verilog counter.v
synth -top counter
dfflibmap -liberty tiny.lib
abc -liberty tiny.lib
stat -liberty tiny.lib
write_verilog -noattr /tmp/mapped.v
EOF
yosys -s /tmp/map.ys > /tmp/map.log 2>&1
echo "-- dfflibmap section:"
awk '/3. Executing DFFLIBMAP/{p=1} /4. Executing ABC/{p=0} p' /tmp/map.log
echo "-- abc transcript tail (ABC RESULTS):"
grep -E 'ABC: \+|ABC RESULTS|Extracted|Re-integrating' /tmp/map.log | tail -25
echo "-- post-map stat:"
awk '/^5\. Printing statistics/{p=1} p' /tmp/map.log | head -24
echo "-- standard-cell instances in mapped netlist /tmp/mapped.v:"
grep -E '^  (DFFRN|INV|NAND2|NOR2|AND2|OR2|XOR2|XNOR2|MUX2) ' /tmp/mapped.v | head -35
echo "-- (netlist header)"
grep -vE '^\s*$' /tmp/mapped.v | head -12

# ---- [3] delay-driven mapping: -D target + -constr ----
echo
echo "================ [3] delay-driven: abc -D 2000 -constr constr.txt ================"
cat > /tmp/delay.ys <<'EOF'
read_verilog counter.v
synth -top counter
dfflibmap -liberty tiny.lib
abc -liberty tiny.lib -D 2000 -constr constr.txt
stat -liberty tiny.lib
EOF
yosys -s /tmp/delay.ys > /tmp/delay.log 2>&1
grep -E 'upsize|dnsize|stime|ABC RESULTS' /tmp/delay.log | tail -12
awk '/^5\. Printing statistics/{p=1} p' /tmp/delay.log | head -24

# ---- [4] latch: cell left unmapped when library has no latch ----
echo
echo "================ [4] latch design: no latch cell in tiny.lib ================"
cat > /tmp/latch.ys <<'EOF'
read_verilog latch.v
synth -top latch_demo
dfflibmap -liberty tiny.lib
abc -liberty tiny.lib
stat
EOF
yosys -s /tmp/latch.ys > /tmp/latch.log 2>&1
awk '/3. Executing DFFLIBMAP/{p=1} p' /tmp/latch.log | grep -vE 'unmapped dff cell|cell DFF |cell DFFRN|\\DFF' | head -30

# ---- [5a] missing liberty on dfflibmap ----
echo
echo "================ [5a] dfflibmap with missing liberty file ================"
cat > /tmp/miss1.ys <<'EOF'
read_verilog counter.v
synth -top counter
dfflibmap -liberty no_such.lib
EOF
yosys -s /tmp/miss1.ys 2>&1 | tail -3 || true

# ---- [5b] missing liberty on abc ----
echo
echo "================ [5b] abc with missing liberty file ================"
cat > /tmp/miss2.ys <<'EOF'
read_verilog counter.v
synth -top counter
abc -liberty no_such.lib
EOF
yosys -s /tmp/miss2.ys > /tmp/miss2.log 2>&1 || true
awk '/3. Executing ABC/{p=1} p' /tmp/miss2.log | head -8
