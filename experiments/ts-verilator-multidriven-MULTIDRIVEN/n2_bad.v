module n2_bad(input wire clk_a, input wire clk_b, input wire a, input wire b, output reg y);
  always @(posedge clk_a) y <= a;
  always @(posedge clk_b) y <= b;   // 同一信号被两个时钟域的 always 块驱动
endmodule
