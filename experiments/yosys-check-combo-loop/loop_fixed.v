// 修复：在环路上插入寄存器，断开组合环
module loop_fixed(input wire clk, input wire rst_n, input wire d, input wire e, output wire y);
  wire a;
  reg c_q;
  assign a = c_q | d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) c_q <= 1'b0;
    else        c_q <= a & e;   // 原来的 c 变成寄存器输出，环被时序断开
  end
  assign y = a ^ c_q;
endmodule
