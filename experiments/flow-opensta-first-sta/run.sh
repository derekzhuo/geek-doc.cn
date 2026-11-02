#!/usr/bin/env bash
# First minimal STA run: tiny liberty + gate netlist + one-clock SDC.
set -u
DOCKER_IMAGE="${DOCKER_IMAGE:-geek-eda:0.3-sta}"

echo "# command: docker run --rm -v \"\$PWD\":/work -w /work ${DOCKER_IMAGE} sta -no_init -exit run_sta.tcl"
echo "# date: 2026-11-03"
echo "# host-toolchain: OpenSTA 2.0.17 (${DOCKER_IMAGE} docker)"
echo

docker run --rm -v "$PWD":/work -w /work "${DOCKER_IMAGE}" sta -no_init -exit run_sta.tcl
