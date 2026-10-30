`timescale 1ns/1ps

module tb_fixed;
  reg source;
  wire continuous_target;
  reg primitive_target;

  initial begin
    source = 1'b0;
    #1 source = 1'b1;
    #1;
    if (continuous_target === 1'b1 && primitive_target === 1'b1) begin
      $display("continuous_target=%b primitive_target=%b", continuous_target, primitive_target);
      $display("PASS: wire continuous assignment and procedural assignment both work");
    end else begin
      $display("FAIL: continuous_target=%b primitive_target=%b", continuous_target, primitive_target);
    end
    $finish;
  end

  assign continuous_target = source;
  always @* primitive_target = source;
endmodule
