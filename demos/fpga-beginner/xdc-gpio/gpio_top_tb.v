`timescale 1ns/1ps
// gpio_top_tb.v —— testbench（不可综合，仅仿真）
// 配套 fpga/beginner/05-xdc-constraints-intro.md。
// 用小参数 CLK_FREQ=10（HALF=5，每 5 周期心跳翻转一次）快速验证：
//   1) led[7:0] 跟随 sw；2) 按键高电平复位；3) led[15] 心跳周期正确。
// 跑法：iverilog -o gpio_sim gpio_top.v gpio_top_tb.v && vvp gpio_sim
module gpio_top_tb;
    reg         clk = 1'b0;
    reg         btn = 1'b1;   // 上电先保持复位(高有效)
    reg  [7:0]  sw  = 8'b0;
    wire [15:0] led;

    integer errors = 0;
    integer toggles = 0;
    reg     last_hb;

    gpio_top #(.CLK_FREQ(10)) dut (
        .clk(clk), .btn(btn), .sw(sw), .led(led)
    );

    always #5 clk = ~clk;   // 10ns 周期

    initial begin
        $dumpfile("gpio_top_tb.vcd");
        $dumpvars(0, gpio_top_tb);

        // 复位阶段：btn=1，心跳应为 0
        repeat (3) @(posedge clk);
        if (led[15] !== 1'b0) begin errors=errors+1; $display("  [FAIL] reset: heartbeat should be 0"); end

        // 释放复位，拨开关 0xA5，检查低 8 位直通
        @(posedge clk);
        btn = 1'b0;
        sw  = 8'hA5;
        #2;
        if (led[7:0] !== 8'hA5) begin
            errors=errors+1;
            $display("  [FAIL] sw passthrough: led[7:0]=%h expect A5", led[7:0]);
        end

        // 统计心跳翻转次数：跑 40 个周期，HALF=5 => 应翻转约 4 次
        last_hb = led[15];
        repeat (40) begin
            @(posedge clk);
            #2;
            if (led[15] !== last_hb) begin toggles = toggles + 1; last_hb = led[15]; end
        end
        // 40 周期 / 5 = 8 个半周期点，翻转次数应在合理范围(>=3)
        if (toggles < 3) begin
            errors=errors+1;
            $display("  [FAIL] heartbeat toggled only %0d times, expect ~4", toggles);
        end

        // 再按一次复位，心跳应归零
        btn = 1'b1;
        repeat (2) @(posedge clk);
        #2;
        if (led[15] !== 1'b0) begin errors=errors+1; $display("  [FAIL] heartbeat not cleared by reset"); end

        $display("---------------------------------------");
        $display("heartbeat toggles=%0d  errors=%0d", toggles, errors);
        if (errors == 0) $display("GPIO TOP SELF-CHECK *** PASSED ***");
        else             $display("GPIO TOP SELF-CHECK *** FAILED ***");
        $finish;
    end
endmodule
