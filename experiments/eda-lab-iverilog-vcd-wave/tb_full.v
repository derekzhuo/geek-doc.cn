// tb_full.v —— 全量 dump：$dumpvars 不带参数，把 TB 以下所有层级的所有信号都写进 VCD
`timescale 1ns/1ps
module tb_full;
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

    always #5 clk = ~clk;   // 100MHz

    integer i;
    initial begin
        $dumpfile("full.vcd");
        $dumpvars;          // 无参数 = 全层级全信号
        repeat (4) @(negedge clk);
        rst_n = 1;
        en = 1;
        // 跑 20000 个时钟，制造足够多的跳变
        for (i = 0; i < 20000; i = i + 1) @(negedge clk);
        $dumpflush;
        $display("FULL DONE count=%0d", count);
        $finish;
    end
endmodule
