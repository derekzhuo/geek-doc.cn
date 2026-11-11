`timescale 1ns/1ps
// 行为级 testbench：只给 verilator --binary 模式使用。
// 带 # 延迟与 @(posedge clk)，Verilator 需 --timing（--binary 自动开启）。
module tb_counter;
    reg        clk   = 0;
    reg        rst_n = 0;
    reg        en    = 0;
    wire [7:0] q;
    wire       carry;

    counter dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));

    // 时钟发生器的阻塞赋值是 Verilog 惯例，显式豁免 BLKSEQ 告警
    /* verilator lint_off BLKSEQ */
    always #5 clk = ~clk;   // 周期 10ns
    /* verilator lint_on BLKSEQ */

    // 进位拉高时记录一次，便于在日志里观察回卷点
    always @(posedge clk) begin
        if (carry)
            $display("[bin-mode] t=%0t  carry pulsed at q=255", $time);
    end

    initial begin
        #22  rst_n = 1;     // 22ns 释放异步复位
        #10  en    = 1;     // 之后打开使能
        repeat (300) @(posedge clk);   // 跑 300 个使能上升沿：300 = 256 + 44
        #1   en    = 0;
        if (q !== 8'd44) begin
            $display("TEST FAIL: expected q=44, got %0d", q);
            $fatal(1);
        end
        $display("[bin-mode] ran 300 enabled cycles, wrapped once, q=%0d", q);
        $display("TEST PASS: q == 44 as expected");
        #20  $finish;
    end
endmodule
