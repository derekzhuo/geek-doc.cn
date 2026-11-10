module dangling(input wire a, input wire b, output wire y);
  wire internal;
  assign internal = a & b;
  assign y = 1'b0;
endmodule
