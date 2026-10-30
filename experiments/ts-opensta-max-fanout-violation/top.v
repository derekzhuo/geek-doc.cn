module top (a, y);
  input a;
  output [5:0] y;
  wire n;

  BUF_X1 u_drive (.A(a), .Y(n));
  BUF_X1 u_load0 (.A(n), .Y(y[0]));
  BUF_X1 u_load1 (.A(n), .Y(y[1]));
  BUF_X1 u_load2 (.A(n), .Y(y[2]));
  BUF_X1 u_load3 (.A(n), .Y(y[3]));
  BUF_X1 u_load4 (.A(n), .Y(y[4]));
  BUF_X1 u_load5 (.A(n), .Y(y[5]));
endmodule
