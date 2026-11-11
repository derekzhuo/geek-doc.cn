// 两级 DFF 流水线，中间插一级 BUF：u_a/Q -> BUF_X1 -> u_b/D
module top (
  input  wire clk,
  input  wire d_in,
  output wire q_out
);
  wire s1;
  wire s2;
  DFF_P  u_a (.D(d_in), .C(clk), .Q(s1));
  BUF_X1 u_x (.A(s1),            .Y(s2));
  DFF_P  u_b (.D(s2),   .C(clk), .Q(q_out));
endmodule
