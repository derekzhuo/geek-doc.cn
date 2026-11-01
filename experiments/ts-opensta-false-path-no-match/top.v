module top (
  input  wire clk,
  input  wire d,
  output wire q
);
  wire s1, s2;
  DFF_P  u_a   (.D(d),  .C(clk), .Q(s1));
  BUF_X1 u_buf (.A(s1), .Y(s2));
  DFF_P  u_b   (.D(s2), .C(clk), .Q(q));
endmodule
