// tb_d0.v —— 深度 0：从 testbench 起全层次记录
`timescale 1ns/1ps
module tb_d0;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [7:0] cnt;
    wire       co;

    cnt_top dut (.clk(clk), .rst_n(rst_n), .cnt(cnt), .co(co));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("depth0.vcd");
        $dumpvars(0, tb_d0);
        #12 rst_n = 1'b1;
        #300 $finish;
    end
endmodule
