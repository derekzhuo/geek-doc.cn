#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p results

netgen-lvs -batch quit > results/version.log 2>&1
netgen-lvs -batch lvs \
  "netlists/layout.spice chip" "netlists/schematic.spice chip" \
  setup.tcl results/comp.out > results/netgen.stdout.log 2>&1
netgen-lvs -batch lvs \
  "netlists/layout_property.spice chip" "netlists/schematic.spice chip" \
  setup.tcl results/property.out > results/property.stdout.log 2>&1

grep -Fq "Netlists match uniquely." results/comp.out
grep -Fq "Cell pin lists are equivalent." results/comp.out
grep -Fq "Device classes chip and chip are equivalent." results/comp.out
if grep -Fq "Property errors" results/comp.out; then
  printf '%s\n' "FAIL: normal comparison unexpectedly contains property errors" >&2
  exit 1
fi
grep -Fq "Property errors were found." results/property.out
grep -Fq "value circuit1: 6e-12   circuit2: 5e-12" results/property.out

{
  printf '%s\n' "Netlists match uniquely."
  printf '%s\n' "Cell pin lists are equivalent; chip and inverter device classes are equivalent."
  printf '%s\n' "Control: value circuit1=6e-12 circuit2=5e-12 (delta=18.2%, cutoff=1%)"
  printf '%s\n' "PASS: normal comparison is unique; control isolates the capacitor property difference"
} | tee results/verification.log
