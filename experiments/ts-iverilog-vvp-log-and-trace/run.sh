#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Icarus Verilog 13.0 / macOS'

printf '\n%s\n' '--- vvp help ---'
printf '%s\n' '$ vvp -h'
vvp -h 2>&1

printf '\n%s\n' '--- compile ---'
printf '%s\n' '$ iverilog -g2012 -Wall -s tb -o demo.vvp tb.v'
iverilog -g2012 -Wall -s tb -o demo.vvp tb.v 2>&1
printf 'exit=%s\n' "$?"
printf '%s\n' '$ iverilog -g2012 -Wall -s no_dump -o no_dump.vvp no_dump.v'
iverilog -g2012 -Wall -s no_dump -o no_dump.vvp no_dump.v 2>&1
printf 'exit=%s\n' "$?"

printf '\n%s\n' '--- default: VCD and stdout ---'
rm -f waves.vcd
printf '%s\n' '$ vvp demo.vvp'
vvp demo.vvp 2>&1
printf 'exit=%s\n' "$?"
printf '%s\n' '$ file waves.vcd'
file waves.vcd

printf '\n%s\n' '--- -l before input: console and logfile ---'
rm -f simulation.log
printf '%s\n' '$ vvp -l simulation.log demo.vvp'
vvp -l simulation.log demo.vvp 2>&1
printf 'exit=%s\n' "$?"
printf '%s\n' '$ cat simulation.log'
cat simulation.log

printf '\n%s\n' '--- -l after input: not parsed as a runtime option ---'
rm -f misplaced.log
printf '%s\n' '$ vvp demo.vvp -l misplaced.log'
vvp demo.vvp -l misplaced.log 2>&1
printf 'exit=%s\n' "$?"
if test -f misplaced.log; then
    printf '%s\n' 'misplaced.log exists: yes'
else
    printf '%s\n' 'misplaced.log exists: no'
fi

printf '\n%s\n' '--- -lxt2 probe: actual log and dump format ---'
rm -f waves.vcd xt2
printf '%s\n' '$ vvp -lxt2 demo.vvp'
vvp -lxt2 demo.vvp 2>&1
printf 'exit=%s\n' "$?"
printf '%s\n' '$ cat xt2'
cat xt2
printf '%s\n' '$ file waves.vcd'
file waves.vcd
printf '%s\n' '$ od -An -c -N8 waves.vcd'
od -An -c -N8 waves.vcd

printf '\n%s\n' '--- -lxt2 without dump tasks ---'
rm -f waves.vcd
printf '%s\n' '$ vvp -lxt2 no_dump.vvp'
vvp -lxt2 no_dump.vvp 2>&1
printf 'exit=%s\n' "$?"
if test -e waves.vcd; then
    printf '%s\n' 'waves.vcd exists: yes'
else
    printf '%s\n' 'waves.vcd exists: no'
fi
