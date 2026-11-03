#!/usr/bin/env bash
# 一条命令复现本篇全部实验：OpenSTA Tcl 脚本 + Yosys Tcl 脚本。
set -u
DOCKER_IMAGE="${DOCKER_IMAGE:-geek-eda:0.4-flow}"

echo "# command: bash run.sh 2>&1 | tee public/shots/flow-tcl-basics-eda/run1.log"
echo "# date: 2026-11-04"
echo "# host-toolchain: OpenSTA 2.0.17 / Yosys 0.33 (${DOCKER_IMAGE} docker)"
echo

echo "########## versions ##########"
docker run --rm -v "$PWD":/work -w /work "${DOCKER_IMAGE}" sta -version
docker run --rm -v "$PWD":/work -w /work "${DOCKER_IMAGE}" yosys -V

echo
echo "########## OpenSTA: sta -no_init -exit sta_flow.tcl ##########"
docker run --rm -v "$PWD":/work -w /work "${DOCKER_IMAGE}" sta -no_init -exit sta_flow.tcl

echo
echo "########## Yosys: yosys -p \"tcl ys_flow.tcl\" ##########"
docker run --rm -v "$PWD":/work -w /work "${DOCKER_IMAGE}" yosys -p "tcl ys_flow.tcl"
