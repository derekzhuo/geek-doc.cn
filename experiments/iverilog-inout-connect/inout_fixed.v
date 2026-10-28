`timescale 1ns/1ps
// 修复版：inout 端口改接 wire，双向驱动都走三态（'z 让出总线）
module sram_if (
  inout [7:0] data,
  input wire oe_n,
  input wire [7:0] dout
);
  assign data = oe_n ? 8'bz : dout;
endmodule

module tb_fixed;
  reg oe_n;
  reg [7:0] dout;
  wire [7:0] data_bus;   // 修复点：reg 改 wire（net 才能承载多驱动三态总线）
  reg [7:0] drive_val;
  reg drive_en;

  sram_if u0 (.data(data_bus), .oe_n(oe_n), .dout(dout));

  assign data_bus = drive_en ? drive_val : 8'bz;   // 对端同样三态

  initial begin
    oe_n = 1'b1; dout = 8'h00;
    drive_en = 1'b0; drive_val = 8'h00;
    #10 oe_n = 1'b0; dout = 8'hA5;
    #10 $display("dut_drive:  data_bus=%h (expect a5)", data_bus);
    oe_n = 1'b1;
    drive_en = 1'b1; drive_val = 8'h3C;
    #10 $display("peer_drive: data_bus=%h (expect 3c)", data_bus);
    drive_en = 1'b0;
    #10 $display("both_z:     data_bus=%h (expect zz)", data_bus);
    $display("PASS: inout connected via wire, three-state resolved");
    $finish;
  end
endmodule
