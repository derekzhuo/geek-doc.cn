`timescale 1ns/1ps
module tb;
    reg clk;
    reg [3:0] count;

    initial begin
        $dumpfile("build/good.vcd");
        $dumpvars(0, tb);
        clk = 1'b0;
        count = 4'd0;
        #5 clk = 1'b1;
        count = 4'd1;
        #5 clk = 1'b0;
        count = 4'd2;
        #5 $finish;
    end
endmodule
