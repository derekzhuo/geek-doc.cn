// tb_window.v —— 演示 $dumpoff / $dumpon / $dumpall 的时间窗控制
`timescale 1ns/1ps
module tb_window;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [7:0] cnt;
    wire       co;

    cnt_top dut (.clk(clk), .rst_n(rst_n), .cnt(cnt), .co(co));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("window.vcd");
        $dumpvars(0, tb_window);
        #12  rst_n = 1'b1;  // 释放复位，计数器开始递增
        #88  $dumpoff;      // 100ns 起暂停记录（预热段不写）
        #100 $dumpon;       // 200ns 恢复记录
              $dumpall;     // 立即补一帧全量当前值快照
        #100 $finish;       // 300ns 结束
    end
endmodule
