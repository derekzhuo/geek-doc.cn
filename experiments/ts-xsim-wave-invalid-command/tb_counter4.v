`timescale 1ns/1ps
module tb_counter4;
    reg  clk = 0;
    reg  rst_n = 0;
    wire [3:0] count;

    counter4 dut (.clk(clk), .rst_n(rst_n), .count(count));

    always #5 clk = ~clk;

    initial begin
        $monitor("%0t ns: rst_n=%b count=%0d (0x%0h)", $time, rst_n, count, count);
        repeat (3) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);
        $display("TEST PASS: counter wrapped, final count=0x%0h", count);
        $finish;
    end
endmodule
