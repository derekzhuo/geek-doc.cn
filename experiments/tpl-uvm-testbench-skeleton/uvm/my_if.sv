`timescale 1ns/1ns
// DUT 物理接口：driver/monitor 通过 virtual interface 碰真实信号
interface my_if(input logic clk, input logic rst_n);
  logic        in_valid;
  logic [7:0]  in_data;
  logic        out_valid;
  logic [7:0]  out_data;
endinterface
