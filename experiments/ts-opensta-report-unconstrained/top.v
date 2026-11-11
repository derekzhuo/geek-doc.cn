module top (
  input  wire clk,
  input  wire d,
  output wire q
);
  wire ck;
  wire stage;
  CLK_BUF u_clkbuf (.A(clk), .Y(ck));
  DFF_P   u_stage  (.D(d), .C(ck), .Q(stage));
  BUF_X1  u_buf    (.A(stage), .Y(q));
endmodule
