module top (
  input  wire clk,
  input  wire d,
  output wire y
);
  wire n1;

  DFFX1 u_stage (
    .D  (d),
    .CK (clk),
    .Q  (n1)
  );

  MISSING_BUF u_out (
    .A (n1),
    .Y (y)
  );
endmodule
