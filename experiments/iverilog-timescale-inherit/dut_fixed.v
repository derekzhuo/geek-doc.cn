// dut_fixed.v —— 修复：补上与测试台一致的 `timescale
`timescale 1ns/1ps

module dut(input wire clk, input wire en, output reg y = 0);
  reg en_d = 0;
  always @(posedge clk) begin
    en_d <= #2 en;
    y    <= #2 en_d;
  end
endmodule
