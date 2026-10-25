`timescale 1ns/1ps
module n6_tb;
  reg a = 0;
  wire y;
  n6_bad u(.a(a), .y(y));
  initial begin
    $dumpfile("n6_wave.vcd");
    $dumpvars(0, n6_tb);
    #10 a = 1;   // a 拉高，但 y 因错连悬空的 sig_data 不跟随
    #20 a = 0;
    #10 $finish;
  end
endmodule
