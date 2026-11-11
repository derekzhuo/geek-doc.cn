module top (
  input  wire clk,
  input  wire d,
  output wire q
);
  wire s1;
  DFF_P u_a (.D(d),  .C(clk), .Q(s1));
  DFF_P u_b (.D(s1), .C(clk), .Q(q));
endmodule
