#!/usr/bin/env bash
# 多角分析教学实验：ss/tt/ff 三档最小库，逐角 setup/hold 报告 + 三个反例
set -u
STA_BIN="${STA_BIN:-sta}"
"$STA_BIN" -version
printf '\n===== multi.tcl: ss/tt/ff 逐角报告 =====\n'
"$STA_BIN" -no_init -exit multi.tcl 2>&1
printf 'MULTI_EXIT=%s\n' "$?"
printf '\n===== bad_missing_flag.tcl: 多角模式下 read_liberty 漏 -corner =====\n'
"$STA_BIN" -no_init -exit bad_missing_flag.tcl 2>&1
printf '\n===== bad_undefined.tcl: -corner 给了未定义的角名 =====\n'
"$STA_BIN" -no_init -exit bad_undefined.tcl 2>&1
printf '\n===== bad_missing_lib.tcl: ff 角未读库（观察静默回退） =====\n'
"$STA_BIN" -no_init -exit bad_missing_lib.tcl 2>&1
