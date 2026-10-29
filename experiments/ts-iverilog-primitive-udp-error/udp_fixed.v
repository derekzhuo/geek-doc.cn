primitive udp_and2(y, a, b);
  output y;
  input a, b;

  table
    // a  b  :  y
     0  0  :  0;
     0  1  :  0;
     1  0  :  0;
     1  1  :  1;
  endtable
endprimitive

module and2_udp(
  input  wire a,
  input  wire b,
  output wire y
);
  udp_and2 u_and2(y, a, b);
endmodule
