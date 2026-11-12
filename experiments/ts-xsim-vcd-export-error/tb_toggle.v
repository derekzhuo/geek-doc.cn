`timescale 1ns/1ps
module tb_toggle;
    reg clk;
    reg rst_n;
    wire [3:0] cnt;

    dut_toggle dut (
        .clk(clk),
        .rst_n(rst_n),
        .cnt(cnt)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        #13 rst_n = 1'b1;
        #300 $finish;
    end
endmodule
