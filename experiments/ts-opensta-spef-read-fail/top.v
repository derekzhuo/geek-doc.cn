module top (clk, d, q);
  input clk, d;
  output q;
  wire n1;
  BUF_X1 u_buf1 (.A(d), .Y(n1));
  BUF_X1 u_buf2 (.A(n1), .Y(q));
endmodule
