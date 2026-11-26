#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p results

netgen-lvs -batch quit > results/version.log 2>&1

# Netgen 1.5.133 can return zero even after a setup error, so inspect diagnostics.
netgen-lvs -batch lvs \
  "netlists/layout.spice chip" "netlists/schematic.spice chip" \
  setup/bad.tcl results/bad.out > results/bad.stdout.log 2>&1
netgen-lvs -batch lvs \
  "netlists/layout.spice chip" "netlists/schematic.spice chip" \
  setup/good.tcl results/good.out > results/good.stdout.log 2>&1

grep -Fq "Warning:  There were errors reading the setup file" results/bad.stdout.log
grep -Fq "Error setup/bad.tcl:3 (ignoring), No such cell!" results/bad.stdout.log
grep -Fq "Property errors were found." results/bad.out
grep -Fq "W circuit1: 2.2e-06   circuit2: 2e-06" results/bad.out

grep -Fq "Result: Circuits match uniquely." results/good.stdout.log
grep -Fq "Netlists match uniquely." results/good.out
grep -Fq "Cell pin lists are equivalent." results/good.out
if grep -Fq "errors reading the setup file" results/good.stdout.log; then
  printf '%s\n' "FAIL: fixed setup still has a setup diagnostic" >&2
  exit 1
fi
if grep -Fq "Property errors" results/good.out; then
  printf '%s\n' "FAIL: fixed setup still has property errors" >&2
  exit 1
fi

{
  printf '%s\n' "BAD: No such cell and Property errors were found (expected)"
  printf '%s\n' "GOOD: Netlists match uniquely; no setup or property errors"
  printf '%s\n' "PASS: correcting pmos_typo to pmos removes the original failure"
} | tee results/verification.log
