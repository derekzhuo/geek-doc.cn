module top (
  input  wire clk,
  input  wire a,
  input  wire b,
  input  wire c,
  output wire y
);
  wire n1;
  AND2_X1 u_and (.A(a), .B(b), .Y(n1));
  XOR2_X1 u_xor (.A(n1), .B(c), .Y(y));
endmodule
