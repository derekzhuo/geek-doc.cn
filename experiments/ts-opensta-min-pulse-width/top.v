module top (
  input  wire clk,
  input  wire d,
  output wire q
);
  DFF_P u_stage (.D(d), .C(clk), .Q(q));
endmodule
