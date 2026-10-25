module n3_bad(input wire clk, input wire d, output reg q1, output reg q2);
  always @(posedge clk) begin
    q1 = d;    // 时序块里用阻塞赋值
    q2 = q1;   // q2 立即拿到 q1 的新值：两级流水塌成一级
  end
endmodule
