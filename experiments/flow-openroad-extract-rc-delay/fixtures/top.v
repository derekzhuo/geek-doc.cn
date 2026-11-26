module top(input d_in, output z_out);
  wire n0, n1, n2, n3, n4;
  BUF_X1 u_buf0 (.A(d_in), .Y(n0));
  BUF_X1 u_buf1 (.A(n0),   .Y(n1));
  BUF_X1 u_buf2 (.A(n1),   .Y(n2));
  BUF_X1 u_buf3 (.A(n2),   .Y(n3));
  BUF_X1 u_buf4 (.A(n3),   .Y(n4));
  BUF_X1 u_buf5 (.A(n4),   .Y(z_out));
endmodule
