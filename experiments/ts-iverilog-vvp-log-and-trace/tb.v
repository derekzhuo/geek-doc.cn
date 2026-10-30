`timescale 1ns/1ps
module tb;
    reg clk;
    reg [3:0] count;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb);
        clk = 1'b0;
        count = 4'd0;
        $display("DISPLAY: simulation start");
        #5 clk = 1'b1;
        count = 4'd1;
        $display("DISPLAY: count=%0d", count);
        #5 clk = 1'b0;
        count = 4'd2;
        $display("DISPLAY: count=%0d", count);
        $display("DISPLAY: simulation finish");
        $finish;
    end
endmodule
