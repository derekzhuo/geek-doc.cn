`timescale 1ns/1ps

module tb_bad;
  reg source;
  reg continuous_target;
  reg primitive_target;

  initial begin
    source = 1'b0;
    #1 source = 1'b1;
    #1 $finish;
  end

  assign continuous_target = source;
  buf primitive_buf(primitive_target, source);
endmodule
