`include "defs.vh"
module tb_inc;
  initial begin
    $display("include demo: DEF_FROM_HEADER=%0d", `DEF_FROM_HEADER);
    $finish;
  end
endmodule
