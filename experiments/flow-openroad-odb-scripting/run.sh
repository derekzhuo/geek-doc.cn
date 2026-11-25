#!/usr/bin/env bash
set -euo pipefail
mkdir -p results

echo '$ openroad -no_init -exit odb_roundtrip.tcl'
openroad -no_init -exit odb_roundtrip.tcl 2>&1

echo '$ openroad -no_init -exit verify_roundtrip.tcl'
openroad -no_init -exit verify_roundtrip.tcl 2>&1

echo '$ diff -u fixtures/input.def results/roundtrip.def'
set +e
diff -u fixtures/input.def results/roundtrip.def > results/before-after.diff
diff_rc=$?
set -e
cat results/before-after.diff
if [[ $diff_rc -ne 1 ]]; then
  echo "DIFF_RESULT FAIL expected real file differences, rc=$diff_rc" >&2
  exit 1
fi
echo "DIFF_RESULT PASS changed DEF lines detected"

set +e
{
  echo '$ openroad -no_init -exit boundary.tcl'
  openroad -no_init -exit boundary.tcl
} > results/boundary.log 2>&1
boundary_rc=$?
set -e
cat results/boundary.log
if [[ $boundary_rc -ne 1 ]] || ! grep -q 'EMPTY_SELECTION: u_missing matched zero instances' results/boundary.log; then
  echo "BOUNDARY_RESULT FAIL expected guarded empty selection, rc=$boundary_rc" >&2
  exit 1
fi
echo "BOUNDARY_RESULT PASS empty selection rejected rc=$boundary_rc"
echo "RUN_RESULT PASS roundtrip and boundary checks completed"
