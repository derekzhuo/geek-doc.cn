// counter_tb.v —— 计数器长仿真测试平台（iverilog / verilator --binary 共用同一份 TB）
// 跑 CYCLES 个时钟（默认 1e7 拍），末尾校验计数值并 PASS/FAIL。
// 注意：本 TB 用了 # 延迟与 @(posedge clk) 等待，verilator 需要 --timing（5.020 起 --binary 不自动开）。
`timescale 1ns/1ps

module counter_tb;

    // 仿真拍数：可用 +define+CYCLES=N 覆盖（verilator 用 -GCYCLES 不行就用 define）
`ifndef CYCLES
    localparam int CYCLES = 10000000;
`else
    localparam int CYCLES = `CYCLES;
`endif

    reg         clk;
    reg         rst_n;
    reg         en;
    wire [31:0] count;

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

    // 激励过程：复位 → 使能 → 跑 CYCLES 拍 → 校验
    initial begin
        rst_n = 1'b0; en = 1'b0;
        #12;                       // 保持复位 12ns
        rst_n = 1'b1;              // 撤复位
        en    = 1'b1;              // 同时使能计数

        repeat (CYCLES) @(posedge clk);
        #1;

        $display("[%0t ns] ran %0d clocks, count=%0d", $time, CYCLES, count);
        if (count == 32'(CYCLES))
            $display("TEST PASS: count == %0d as expected", CYCLES);
        else begin
            $display("TEST FAIL: count=%0d, expected %0d", count, CYCLES);
            $fatal(1);
        end
        $finish;
    end

    // 不在每个时钟沿 $display —— 打印 I/O 会淹没仿真器本身的速度差异。

endmodule
