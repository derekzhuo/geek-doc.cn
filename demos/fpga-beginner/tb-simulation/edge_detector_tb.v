`timescale 1ns/1ps
// edge_detector_tb.v —— 时序逻辑的测试台（不可综合，仅仿真）
// 配套 fpga/beginner/04-testbench-simulation.md。
// 演示：时钟生成、复位序列、在时钟沿上同步施加激励、$monitor 打印、VCD 波形。
// 跑法：iverilog -o edge_sim edge_detector.v edge_detector_tb.v && vvp edge_sim
module edge_detector_tb;
    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    reg sig   = 1'b0;
    wire rise_pulse;

    integer errors = 0;

    edge_detector dut (
        .clk(clk), .rst_n(rst_n), .sig(sig),
        .rise_pulse(rise_pulse)
    );

    // 时钟生成：每 5ns 翻转 => 周期 10ns => 100MHz
    always #5 clk = ~clk;

    initial begin
        $dumpfile("edge_detector_tb.vcd");
        $dumpvars(0, edge_detector_tb);
        // 每次信号变化打印一行，相当于最便宜的「文本逻辑分析仪」
        $monitor("t=%0t  rst_n=%b  sig=%b  rise_pulse=%b", $time, rst_n, sig, rise_pulse);

        // 1) 复位阶段：先拉低复位一段时间再释放
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // 2) 制造一个上升沿：在时钟沿把 sig 拉高
        @(posedge clk);
        sig = 1'b1;
        #2;                                  // 沿后稍等，让组合输出稳定
        if (rise_pulse !== 1'b1) begin
            errors = errors + 1;
            $display("  [FAIL] expected rise_pulse=1 after sig rising edge");
        end

        // 3) 下一拍 sig_d 已追上 sig，脉冲应消失
        @(posedge clk);
        #2;
        if (rise_pulse !== 1'b0) begin
            errors = errors + 1;
            $display("  [FAIL] rise_pulse should be 0 one cycle later");
        end

        // 4) 制造一个下降沿：不应产生上升脉冲
        @(posedge clk);
        sig = 1'b0;
        @(posedge clk);
        #2;
        if (rise_pulse !== 1'b0) begin
            errors = errors + 1;
            $display("  [FAIL] falling edge must not produce rise_pulse");
        end

        // 5) 再来一个上升沿确认能重复触发
        @(posedge clk);
        sig = 1'b1;
        #2;
        if (rise_pulse !== 1'b1) begin
            errors = errors + 1;
            $display("  [FAIL] second rising edge not detected");
        end

        repeat (2) @(posedge clk);
        $display("---------------------------------------");
        if (errors == 0)
            $display("EDGE DETECTOR SELF-CHECK *** PASSED ***");
        else
            $display("EDGE DETECTOR SELF-CHECK *** FAILED *** errors=%0d", errors);
        $finish;
    end
endmodule
