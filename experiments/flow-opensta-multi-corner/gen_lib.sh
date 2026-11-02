#!/usr/bin/env bash
# 用法: gen_lib.sh <角点名> <cq> <buf> <setup> <hold> <tran>
set -u
name=$1; cq=$2; buf=$3; setup=$4; hold=$5; tran=$6
cat > "${name}.lib" <<LIB
/* 教学用最小 liberty：${name} 工艺角，标量延时，不对应任何真实工艺；产线请替换为 PDK 签核库 */
library(${name}_teaching) {
  time_unit : "1ns";
  delay_model : table_lookup;
  voltage_unit : "1V";
  current_unit : "1mA";
  capacitive_load_unit(1, pf);
  input_threshold_pct_rise : 50.0;
  output_threshold_pct_rise : 50.0;
  slew_lower_threshold_pct_rise : 20.0;
  slew_upper_threshold_pct_rise : 80.0;
  input_threshold_pct_fall : 50.0;
  output_threshold_pct_fall : 50.0;
  slew_lower_threshold_pct_fall : 20.0;
  slew_upper_threshold_pct_fall : 80.0;
  cell(DFF_P) {
    ff(IQ, IQN) { clocked_on : "C"; next_state : "D"; }
    pin(D) {
      direction : input;
      timing() {
        related_pin : "C";
        timing_type : setup_rising;
        rise_constraint(scalar) { values("${setup}"); }
        fall_constraint(scalar) { values("${setup}"); }
      }
      timing() {
        related_pin : "C";
        timing_type : hold_rising;
        rise_constraint(scalar) { values("${hold}"); }
        fall_constraint(scalar) { values("${hold}"); }
      }
    }
    pin(C) { direction : input; clock : true; }
    pin(Q) {
      direction : output;
      function : "IQ";
      timing() {
        related_pin : "C";
        timing_type : rising_edge;
        cell_rise(scalar) { values("${cq}"); }
        cell_fall(scalar) { values("${cq}"); }
        rise_transition(scalar) { values("${tran}"); }
        fall_transition(scalar) { values("${tran}"); }
      }
    }
  }
  cell(BUF_X1) {
    pin(A) { direction : input; }
    pin(Y) {
      direction : output;
      function : "A";
      timing() {
        related_pin : "A";
        timing_type : combinational;
        cell_rise(scalar) { values("${buf}"); }
        cell_fall(scalar) { values("${buf}"); }
        rise_transition(scalar) { values("${tran}"); }
        fall_transition(scalar) { values("${tran}"); }
      }
    }
  }
}
LIB
