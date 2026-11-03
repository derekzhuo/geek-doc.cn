`timescale 1ns/1ns
// 顶层 module：时钟复位、DUT 例化、interface 经 config_db 送进平台
module top_tb;
  logic clk = 0;
  logic rst_n;

  my_if if0(.clk(clk), .rst_n(rst_n));

  dut u_dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid (if0.in_valid),  .in_data (if0.in_data),
    .out_valid(if0.out_valid), .out_data(if0.out_data)
  );

  initial forever #5ns clk = ~clk;

  initial begin
    rst_n = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual my_if)::set(uvm_root::get(), "*", "vif", if0);
    run_test("my_test");
  end
endmodule
