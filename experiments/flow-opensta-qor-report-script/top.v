module top (
  input  wire clk,
  input  wire d_in,
  output wire ctrl_tx,
  output wire data_tx
);
  wire c0q, c1d, d0q, d1q, d1d, d2d, n1, n2, n3, n5, n6, n7, n8;
  wire ck1, ck2, ck3, ck4;
  BUF_X u_ck_b1 (.A(clk),  .Y(ck1));
  BUF_X u_ck_b2 (.A(ck1),  .Y(ck2));
  BUF_X u_ck_b3 (.A(ck2),  .Y(ck3));
  BUF_X u_ck_b4 (.A(ck3),  .Y(ck4));

  DFF_P u_ctrl0 (.C(ck1), .D(d_in), .Q(c0q));
  NAND2 u_ctrl_nand (.A(c0q), .B(c0q), .Y(c1d));
  DFF_P u_ctrl1 (.C(ck1), .D(c1d), .Q(ctrl_tx));

  DFF_P u_data0 (.C(ck1), .D(d_in), .Q(d0q));
  BUF_X u_d_b0 (.A(d0q), .Y(n1));
  BUF_X u_d_b1 (.A(n1), .Y(n2));
  BUF_X u_d_b2 (.A(n2), .Y(n3));
  BUF_X u_d_b3 (.A(n3), .Y(d1d));
  DFF_P u_data1 (.C(ck2), .D(d1d), .Q(d1q));
  BUF_X u_d_b4 (.A(d1q), .Y(n5));
  BUF_X u_d_b5 (.A(n5), .Y(n6));
  BUF_X u_d_b6 (.A(n6), .Y(n7));
  BUF_X u_d_b7 (.A(n7), .Y(n8));
  BUF_X u_d_b8 (.A(n8), .Y(d2d));
  DFF_P u_data2 (.C(ck4), .D(d2d), .Q(data_tx));
endmodule
