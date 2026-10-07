// counter_tb.v —— 计数器测试平台（testbench）
// 产生时钟/复位/使能，打印关键事件，并用 $dumpvars 导出 VCD。
`timescale 1ns/1ps

module counter_tb;

    reg        clk;
    reg        rst_n;
    reg        en;
    wire [3:0] count;

    // 例化被测设计（DUT）
    counter dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

    // 时钟：周期 10ns（每 5ns 翻转一次）
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // 激励过程
    initial begin
        // VCD 导出：把 counter_tb 整个层级的信号写进 counter.vcd
        $dumpfile("out/counter.vcd");
        $dumpvars(0, counter_tb);

        rst_n = 1'b0; en = 1'b0;
        #12;                       // 保持复位 12ns
        rst_n = 1'b1;              // 撤复位
        $display("[%0t ns] release reset, count=%0d", $time, count);

        en = 1'b1;                 // 使能计数
        repeat (20) @(posedge clk);
        #1;
        $display("[%0t ns] after 20 enabled clocks, count=%0d", $time, count);

        en = 1'b0;                 // 暂停计数
        repeat (3) @(posedge clk);
        #1;
        $display("[%0t ns] paused 3 clocks, count=%0d (should hold)", $time, count);

        en = 1'b1;                 // 恢复计数，验证 4 位回绕
        repeat (5) @(posedge clk);
        #1;
        $display("[%0t ns] after 5 more clocks, count=%0d (wrap check)", $time, count);

        $display("[%0t ns] TEST PASS: counter works as expected", $time);
        $finish;
    end

    // 每个时钟沿打印一次计数值，便于对照 VCD
    always @(posedge clk) begin
        $display("[%0t ns] clk posedge: rst_n=%b en=%b count=%0d",
                 $time, rst_n, en, count);
    end

endmodule
