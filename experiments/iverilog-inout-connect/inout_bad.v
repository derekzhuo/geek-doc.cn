`timescale 1ns/1ps
// 错误示范：把 inout 端口连接到 reg 变量上
// inout 是双向总线，必须由 wire（net）承载；reg 是过程赋值变量，不能挂到三态总线上
module sram_if (
  inout [7:0] data,   // 双向数据总线
  input wire oe_n,    // 输出使能，低有效
  input wire [7:0] dout
);
  assign data = oe_n ? 8'bz : dout;   // 三态驱动：不输出时让出总线
endmodule

module tb_bad;
  reg oe_n;
  reg [7:0] dout;
  reg [7:0] data_bus;   // 错在这里：inout 口接了 reg
  reg [7:0] drive_val;
  reg drive_en;

  sram_if u0 (.data(data_bus), .oe_n(oe_n), .dout(dout));

  // 测试台想从另一侧驱动同一总线（模拟对端器件）
  assign data_bus = drive_en ? drive_val : 8'bz;

  initial begin
    oe_n = 1'b1; dout = 8'h00;
    drive_en = 1'b0; drive_val = 8'h00;
    #10 oe_n = 1'b0; dout = 8'hA5;   // DUT 输出方向
    #10 oe_n = 1'b1;
    drive_en = 1'b1; drive_val = 8'h3C;  // 对端驱动方向
    #10 $display("data_bus=%h", data_bus);
    $finish;
  end
endmodule
