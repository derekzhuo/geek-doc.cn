primitive udp_and2_bad(y, a, b);
  output y;
  input a, b;

  table
    // a  b  :  y
     0  0  :  0;
     0  1  :  0;
     1  0  :  0;
     1  1  0  :  1;
  endtable
endprimitive
