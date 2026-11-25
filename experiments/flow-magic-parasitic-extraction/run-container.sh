#!/usr/bin/env bash
set -euo pipefail

canonical_mos() {
  awk '
    /^M/ {
      sub(/^M[^[:space:]]+[[:space:]]+/, "M ")
      capture=1
      print
      next
    }
    capture && /^\+/ { print; next }
    capture { exit }
  ' "$1"
}

printf '%s\n' '$ magic --version'
magic --version
printf '%s\n' '$ xvfb-run -a magic -noconsole -dnull -T scmos < extract.tcl'
rm -f nmos.ext nmos.spice nmos_c0.spice nmos_cthresh1000.spice
xvfb-run -a magic -noconsole -dnull -T scmos < extract.tcl

printf '%s\n' '--- nmos_reference.spice ---'
sed -n '1,80p' nmos_reference.spice
printf '%s\n' '--- nmos_c0.spice ---'
sed -n '1,80p' nmos_c0.spice
printf '%s\n' '--- nmos_cthresh1000.spice ---'
sed -n '1,80p' nmos_cthresh1000.spice
printf '%s\n' '--- extracted node and device records ---'
grep -E '^(device|node) ' nmos.ext

test "$(grep -c '^device ' nmos.ext)" -eq 1
test "$(grep -c '^M' nmos_reference.spice)" -eq 1
test "$(grep -c '^M' nmos_c0.spice)" -eq 1
cmp <(canonical_mos nmos_reference.spice) <(canonical_mos nmos_c0.spice)
grep -Fq 'C0 g Gnd 3.18fF' nmos_c0.spice
if grep -q '^C' nmos_cthresh1000.spice; then
  printf '%s\n' 'FAIL: capacitance survived cthresh 1000' >&2
  exit 1
fi
cmp <(canonical_mos nmos_c0.spice) <(canonical_mos nmos_cthresh1000.spice)
printf '%s\n' 'PASS: one extracted device and one output MOS; complete record matches reference'
printf '%s\n' 'PASS: cthresh 0 preserves C0=3.18fF; cthresh 1000 removes it'
printf '%s\n' 'PASS: complete MOS records including continuations match across options'
