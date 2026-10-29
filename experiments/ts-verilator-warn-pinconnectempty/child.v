module child (
    input  wire in,
    output wire out,
    output wire debug
);
  assign out = in;
  assign debug = in;
endmodule
