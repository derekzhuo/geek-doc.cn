// tb_d1.v —— 深度 1：只记录 testbench 顶层这一层
`timescale 1ns/1ps
module tb_d1;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [7:0] cnt;
    wire       co;

    cnt_top dut (.clk(clk), .rst_n(rst_n), .cnt(cnt), .co(co));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("depth1.vcd");
        $dumpvars(1, tb_d1);
        #12 rst_n = 1'b1;
        #300 $finish;
    end
endmodule
