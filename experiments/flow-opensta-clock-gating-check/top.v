module top(clk, en_in, d, q);
  input clk, en_in, d;
  output q;
  wire en_q, en_b, gclk;
  DFF_X1  u_enff (.C(clk),  .D(en_in), .Q(en_q));
  BUF_X1  u_enbuf(.A(en_q), .Y(en_b));
  AND2_X1 u_gate (.A(clk), .B(en_b), .Y(gclk));
  DFF_X1  u_dff  (.C(gclk), .D(d),     .Q(q));
endmodule
