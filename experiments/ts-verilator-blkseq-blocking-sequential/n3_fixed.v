module n3_fixed(input wire clk, input wire d, output reg q1, output reg q2);
  always @(posedge clk) begin
    q1 <= d;
    q2 <= q1;  // q2 拿到 q1 的旧值：标准两级流水
  end
endmodule
