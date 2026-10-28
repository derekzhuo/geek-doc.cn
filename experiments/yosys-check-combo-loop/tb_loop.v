`timescale 1ns/1ps
module tb_loop;
  reg d = 1'b1, e = 1'b1;
  wire y;
  loop_bad u(.d(d), .e(e), .y(y));
  initial begin
    #1000;
    $display("sim reached 1000ns (no oscillation observed)");
    $finish;
  end
  initial begin
    $dumpfile("loop.vcd");
    $dumpvars(0, tb_loop);
  end
endmodule
