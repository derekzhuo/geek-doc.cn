`timescale 1ns/1ps
module tb;
    reg  a;
    wire y;

    scope_fixed dut (.a(a), .y(y));

    initial begin
        a = 1'b0;
        #1;
        if (y !== 1'b0) $fatal(1, "FAIL: a=0 must produce y=0");
        a = 1'b1;
        #1;
        if (y !== 1'b1) $fatal(1, "FAIL: a=1 must produce y=1");
        $display("PASS: repaired module scopes compile and simulate");
        $finish;
    end
endmodule
