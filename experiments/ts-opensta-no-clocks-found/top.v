module top (
  input  wire clk,
  input  wire d,
  output wire q
);
  wire stage;
  DFF_P u_stage (.D(d), .C(clk), .Q(stage));
  BUF_X1 u_buf  (.A(stage), .Y(q));
endmodule
