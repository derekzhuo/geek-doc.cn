// `default_nettype none 防线：隐式声明直接变 Error
`default_nettype none
module implicit_none (
    input  wire a,
    input  wire b,
    output wire y
);
  // default_nettype none 生效后，未声明的 sum_ab 不再被静默接受
  assign sum_ab = a & b;
  assign y      = sum_ab;
endmodule
`default_nettype wire
