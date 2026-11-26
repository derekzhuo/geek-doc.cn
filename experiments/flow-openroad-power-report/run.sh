#!/usr/bin/env bash
set -euo pipefail
mkdir -p results

echo '# command: bash run.sh'
echo "# date: $(TZ=Asia/Shanghai date +%F)"
echo '# host-toolchain: OpenROAD 26Q4 / Icarus Verilog 12.0 / Python 3.12'

echo '$ openroad -version'
openroad -version
echo '$ iverilog -V'
iverilog -V 2>/dev/null | /usr/bin/head -n 2
echo '$ python3 --version'
python3 --version

echo '$ iverilog -g2012 -o results/tb.vvp fixtures/top.v tb/cells.v tb/tb.v'
iverilog -g2012 -o results/tb.vvp fixtures/top.v tb/cells.v tb/tb.v
echo '$ vvp results/tb.vvp'
vvp results/tb.vvp

echo '$ python3 scripts/vcd_to_saif.py results/activity.vcd results/activity.saif --scope tb/dut --duration 90'
python3 scripts/vcd_to_saif.py results/activity.vcd results/activity.saif --scope tb/dut --duration 90
echo '$ python3 scripts/vcd_to_saif.py results/activity.vcd results/activity-unmapped.saif --scope tb/dut --duration 90 --extra-unmapped ghost'
python3 scripts/vcd_to_saif.py results/activity.vcd results/activity-unmapped.saif --scope tb/dut --duration 90 --extra-unmapped ghost

echo '$ openroad -no_init -exit power_saif.tcl'
openroad -no_init -exit power_saif.tcl 2>&1 | tee results/power-saif.log
grep -q 'Annotated 5 pin activities.' results/power-saif.log
grep -q '9.763717799e-07' results/power-saif.log

echo '$ openroad -no_init -exit power_vectorless.tcl'
openroad -no_init -exit power_vectorless.tcl 2>&1 | tee results/power-vectorless.log
grep -q '4.328659884e-07' results/power-vectorless.log

set +e
echo '$ openroad -no_init -exit power_missing_scope.tcl'
openroad -no_init -exit power_missing_scope.tcl > results/power-missing-scope.log 2>&1
missing_rc=$?
set -e
cat results/power-missing-scope.log
echo "MISSING_SCOPE_EXIT=$missing_rc"
if [[ $missing_rc -ne 0 ]]; then
  echo 'MISSING_SCOPE_RESULT FAIL unexpected nonzero exit' >&2
  exit 1
fi
grep -q 'Annotated 0 pin activities.' results/power-missing-scope.log

echo '$ openroad -no_init -exit power_unmapped.tcl'
openroad -no_init -exit power_unmapped.tcl 2>&1 | tee results/power-unmapped.log
grep -q 'Annotated 5 pin activities.' results/power-unmapped.log

echo 'RUN_RESULT PASS simulation, SAIF conversion, two power cases and two boundaries completed'
