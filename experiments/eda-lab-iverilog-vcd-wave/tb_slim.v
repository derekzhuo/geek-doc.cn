// tb_slim.v —— 瘦身 dump：同一设计、同一激励，只 dump TB 顶层 1 层信号，
// 并用 $dumpon/$dumpoff 跳过复位后的前 1000 拍预热段。
`timescale 1ns/1ps
module tb_slim;
    reg        clk = 0;
    reg        rst_n = 0;
    reg        en = 0;
    wire [7:0] count;
    wire       tick;

    counter_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count),
        .tick  (tick)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("slim.vcd");
        // depth=1：只记录 tb_slim 这一层的信号（clk/rst_n/en/count/tick），
        // dut 内部和 u_baud 内部全部不进 VCD
        $dumpvars(1, tb_slim);
        repeat (4) @(negedge clk);
        rst_n = 1;
        en = 1;
        // 前 1000 拍是预热，不看 → 暂停 dump
        $dumpoff;
        for (i = 0; i < 1000; i = i + 1) @(negedge clk);
        $dumpon;
        for (i = 0; i < 19000; i = i + 1) @(negedge clk);
        $dumpflush;
        $display("SLIM DONE count=%0d", count);
        $finish;
    end
endmodule
