`timescale 1ns/1ns
// 最小 DUT 接口：时钟复位 + 输入握手 + 一拍延迟的输出
interface dut_if();
  logic        clk;
  logic        rst_n;
  logic        in_valid;
  logic [7:0]  in_data;
  logic        out_valid;
  logic [7:0]  out_data;
endinterface
