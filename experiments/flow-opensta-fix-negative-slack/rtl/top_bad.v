// 违例版本：两级寄存器之间串四级 BUF，组合路径长
module top (
  input  wire clk,
  input  wire d_in,
  output reg  q_out
);
  wire c0, c1, c2, c3;
  reg  s0;

  BUF_X1 u0 (.A(s0), .Y(c0));
  BUF_X1 u1 (.A(c0), .Y(c1));
  BUF_X1 u2 (.A(c1), .Y(c2));
  BUF_X1 u3 (.A(c2), .Y(c3));

  always @(posedge clk) begin
    s0    <= d_in;
    q_out <= c3;
  end
endmodule
