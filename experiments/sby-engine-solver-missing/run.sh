#!/bin/bash
# SymbiYosys smtbmc engine with missing SMT solver.
# Environment note: this box ships apt yosys 0.9 (no smtbmc pass); use a matching
# toolchain (here oss-cad-suite yosys 0.43) so the failure is really about the solver.
set -u
OSS=${OSS:-$HOME/oss-cad-suite/bin}
VENV=/opt/eda-venv/bin

echo "== CASE A: host apt yosys 0.9 has no smtbmc (modern sby script rejected) =="
PATH=/usr/local/bin:/usr/bin:/bin sby -f tiny.sby | tee c5-host.log || true

echo "== CASE B: smtbmc-capable yosys, but z3 hidden from PATH =="
mv "$OSS/z3" /tmp/_z3_hidden
PATH=$OSS:/usr/bin:/bin sby -f tiny.sby | tee c5-bad.log || true
mv /tmp/_z3_hidden "$OSS/z3"

echo "== CASE C (fix): pip install z3-solver into /opt/eda-venv, rerun =="
sudo "$VENV/pip" install z3-solver
mv "$OSS/z3" /tmp/_z3_hidden
PATH=$VENV:$OSS:/usr/bin:/bin sby -f tiny.sby | tee c5-good.log
mv /tmp/_z3_hidden "$OSS/z3"
