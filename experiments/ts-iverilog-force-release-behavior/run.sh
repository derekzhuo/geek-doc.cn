#!/usr/bin/env bash
set -euo pipefail

trap 'rm -f simv' EXIT

version_output="$(iverilog -V 2>/dev/null)"
version_line="${version_output%%$'\n'*}"
printf '# command: iverilog -g2012 -s tb -o simv tb.v && vvp simv\n'
printf '# date: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
printf '# host-toolchain: %s / %s\n' "$(uname -srm)" "$version_line"
printf '$ iverilog -g2012 -s tb -o simv tb.v && vvp simv\n'
iverilog -g2012 -s tb -o simv tb.v
vvp simv
