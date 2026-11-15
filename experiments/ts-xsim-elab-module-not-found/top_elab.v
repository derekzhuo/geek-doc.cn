`timescale 1ns/1ps

module top_elab;

  reg  a;
  reg  b;
  wire y;

  and_gate u_gate (
    .a(a),
    .b(b),
    .y(y)
  );

  initial begin
    a = 1'b0;
    b = 1'b0;
    #10;
    a = 1'b1;
    b = 1'b1;
    #10;
    $display("ELAB_SIM_RESULT a=%0b b=%0b y=%0b", a, b, y);
    $finish;
  end

endmodule
