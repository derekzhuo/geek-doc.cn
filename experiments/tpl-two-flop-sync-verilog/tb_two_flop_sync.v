// tb_two_flop_sync.v —— 两级同步器 testbench
// 源时钟 100MHz（10ns 周期），目标时钟 40MHz（25ns 周期）
// 场景1: 基本版——源域脉冲展宽后跨域，同步输出不得丢失
// 场景2: 边沿检测版——每个异步脉冲在目标域只产生一个单周期脉冲
`timescale 1ns/1ps

module tb_two_flop_sync;
    reg clk_src = 1'b0;
    reg clk_dst = 1'b0;
    reg rst_n   = 1'b0;
    reg sig_async = 1'b0;

    wire sig_sync_basic;
    wire sig_sync_rst;
    wire sig_pulse_edge;

    // 100MHz 源时钟
    always #5 clk_src = ~clk_src;
    // 40MHz 目标时钟
    always #12.5 clk_dst = ~clk_dst;

    two_flop_sync u_basic (
        .clk_dst   (clk_dst),
        .sig_async (sig_async),
        .sig_sync  (sig_sync_basic)
    );

    two_flop_sync_rst u_rst (
        .clk_dst   (clk_dst),
        .rst_n     (rst_n),
        .sig_async (sig_async),
        .sig_sync  (sig_sync_rst)
    );

    two_flop_sync_edge u_edge (
        .clk_dst   (clk_dst),
        .rst_n     (rst_n),
        .sig_async (sig_async),
        .sig_pulse (sig_pulse_edge)
    );

    // 统计
    integer src_pulse_cnt  = 0;  // 源域发出的脉冲数
    integer basic_rise_cnt = 0;  // 基本版输出上升沿数
    integer edge_pulse_cnt = 0;  // 边沿版输出脉冲数
    integer edge_bad_width = 0;  // 边沿版脉冲宽度异常次数（非单周期）

    // 源域脉冲展宽：在 100MHz 域拉高 6 个源周期（60ns > 25ns 目标周期）
    task send_stretched_pulse;
        begin
            @(posedge clk_src);
            sig_async <= 1'b1;
            repeat (6) @(posedge clk_src);
            sig_async <= 1'b0;
            src_pulse_cnt = src_pulse_cnt + 1;
            // 脉冲间拉开间隔，避免与边沿检测混淆
            repeat (10) @(posedge clk_src);
        end
    endtask

    // 基本版输出上升沿计数
    reg basic_d = 1'b0;
    always @(posedge clk_dst) begin
        basic_d <= sig_sync_basic;
        if (sig_sync_basic & ~basic_d)
            basic_rise_cnt = basic_rise_cnt + 1;
    end

    // 边沿版脉冲计数 + 宽度检查（脉冲之间必须恰好隔开一个 clk_dst 低电平）
    reg edge_d = 1'b0;
    always @(posedge clk_dst) begin
        edge_d <= sig_pulse_edge;
        if (sig_pulse_edge & ~edge_d)
            edge_pulse_cnt = edge_pulse_cnt + 1;
        if (sig_pulse_edge & edge_d)
            edge_bad_width = edge_bad_width + 1; // 连续两拍为高 = 宽度超标
    end

    initial begin
        $dumpfile("tb_two_flop_sync.vcd");
        $dumpvars(0, tb_two_flop_sync);

        // 复位
        rst_n = 1'b0;
        repeat (5) @(posedge clk_dst);
        rst_n = 1'b1;
        repeat (2) @(posedge clk_dst);

        // 场景1+2 合并：发 5 个展宽脉冲
        repeat (5) send_stretched_pulse;

        // 等最后一级同步器稳定
        repeat (10) @(posedge clk_dst);

        $display("==== two_flop_sync TB result ====");
        $display("src pulses sent        : %0d", src_pulse_cnt);
        $display("basic sync rises seen  : %0d", basic_rise_cnt);
        $display("edge pulses seen       : %0d", edge_pulse_cnt);
        $display("edge bad width count   : %0d", edge_bad_width);

        if (basic_rise_cnt == src_pulse_cnt &&
            edge_pulse_cnt == src_pulse_cnt &&
            edge_bad_width == 0)
            $display("PASS: all pulses synchronized, edge version outputs single-cycle pulses");
        else
            $display("FAIL: pulse lost or pulse width abnormal");
        $finish;
    end

    // 看门狗
    initial begin
        #5000;
        $display("FAIL: timeout");
        $finish;
    end
endmodule
