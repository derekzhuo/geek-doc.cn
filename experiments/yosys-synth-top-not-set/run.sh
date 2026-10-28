#!/bin/sh
# 一条线演示：synth 不带 -top / -top 指错 → stat 对比 → 修复复跑
set +e

echo '########## [1/4] 复现一：synth 不带 -top（设计里混着孤儿模块 glitch_filter）'
yosys -Q -T -p 'read_verilog chip_top.v uart_tx.v pwm_led.v debounce.v glitch_filter.v; synth; stat' 2>&1 | grep -E 'HIERARCHY|Removing unused|===|Number of cells|Warning|ERROR'
echo

echo '########## [2/4] 复现二：-top 指错（把子模块 uart_tx 当顶层）'
yosys -Q -T -p 'read_verilog chip_top.v uart_tx.v pwm_led.v debounce.v glitch_filter.v; synth -top uart_tx; stat' 2>&1 | grep -E 'HIERARCHY|Removing unused|===|Number of cells|Warning|ERROR'
echo

echo '########## [3/4] 修复：synth -top chip_top（显式锚定真顶层）'
yosys -Q -T -p 'read_verilog chip_top.v uart_tx.v pwm_led.v debounce.v glitch_filter.v; synth -top chip_top; stat' 2>&1 | grep -E 'HIERARCHY|Removing unused|===|Number of cells|Warning|ERROR'
echo

echo '########## [4/4] flatten 视角：synth -top chip_top -flatten'
yosys -Q -T -p 'read_verilog chip_top.v uart_tx.v pwm_led.v debounce.v glitch_filter.v; synth -top chip_top -flatten; stat' 2>&1 | grep -E 'HIERARCHY|Removing unused|===|Number of cells|Warning|ERROR'
