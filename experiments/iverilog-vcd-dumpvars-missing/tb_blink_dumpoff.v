`timescale 1ns/1ps
module tb_blink;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire led;

    blink dut (.clk(clk), .rst_n(rst_n), .led(led));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("blink_off.vcd");
        $dumpvars(0, tb_blink);
        $dumpoff;          // 暂停记录，之后忘记 $dumpon
        #12 rst_n = 1'b1;
        #100;
        $display("sim done, led=%b", led);
        $finish;
    end
endmodule
