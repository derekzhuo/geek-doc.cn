`default_nettype none
module n6_sub(input wire d, output wire q);
  assign q = d;
endmodule
module n6_none(input wire a, output wire y);
  wire sig_data;
  n6_sub u(.d(a), .q(sig_daat));   // 同样的拼写错，现在直接报 error
  assign y = sig_data;
endmodule
