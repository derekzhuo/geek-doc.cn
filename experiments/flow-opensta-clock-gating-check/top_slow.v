module top(clk, en_in, d, q);
  input clk, en_in, d;
  output q;
  wire en_q, e1, e2, en_b, gclk;
  DFF_X1  u_enff (.C(clk), .D(en_in), .Q(en_q));
  BUF_D1  u_b1   (.A(en_q), .Y(e1));
  BUF_D1  u_b2   (.A(e1),   .Y(e2));
  BUF_X1  u_enbuf(.A(e2),   .Y(en_b));
  AND2_X1 u_gate (.A(clk), .B(en_b), .Y(gclk));
  DFF_X1  u_dff  (.C(gclk), .D(d),    .Q(q));
endmodule
