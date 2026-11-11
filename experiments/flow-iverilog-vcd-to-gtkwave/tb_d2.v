// tb_d2.v —— 深度 2：记录 testbench 与 dut 层，不进 u_inc
`timescale 1ns/1ps
module tb_d2;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [7:0] cnt;
    wire       co;

    cnt_top dut (.clk(clk), .rst_n(rst_n), .cnt(cnt), .co(co));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("depth2.vcd");
        $dumpvars(2, tb_d2);
        #12 rst_n = 1'b1;
        #300 $finish;
    end
endmodule
