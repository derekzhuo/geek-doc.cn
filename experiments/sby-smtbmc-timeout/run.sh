#!/bin/bash
# smtbmc depth too small -> no conclusion within bound; enlarge depth -> hit.
set -u
OSS=${OSS:-$HOME/oss-cad-suite/bin}
export PATH=$OSS:/opt/eda-venv/bin:/usr/bin:/bin

echo "== cover, depth 3: target needs step 11 -> unreached within bound =="
sby -f cov3.sby | tee c6-cov3.log || true

echo "== cover, depth 12 -> reached at step 11, PASS =="
sby -f cov12.sby | tee c6-cov12.log

echo "== bmc assert, depth 3 -> bounded PASS (no counterexample within 3 cycles) =="
sby -f bound3.sby | tee c6-bound3.log

echo "== bmc assert, depth 12 -> counterexample, FAIL =="
sby -f bound12.sby | tee c6-bound12.log || true
