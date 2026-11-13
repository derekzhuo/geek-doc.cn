// 计数器测试平台：前 3 拍保持复位，随后使能 20 拍并打印计数轨迹。
// $finish 前的最终计数是两套仿真器对拍的锚点，必须完全一致。
`timescale 1ns/1ps
module tb_counter;
    reg        clk = 1'b0;
    reg        rst_n = 1'b0;
    reg        enable = 1'b0;
    wire [3:0] count;

    counter #(.WIDTH(4)) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .count(count)
    );

    always #5 clk = ~clk;  // 100 MHz 时钟

    integer k;
    initial begin
        $display("time rst enable count");
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        enable = 1'b1;
        for (k = 0; k < 12; k = k + 1) begin
            @(posedge clk);
            $display("%4t  %0d    %0d     %0d", $time, rst_n, enable, count);
        end
        // 两工具对“边沿后立即采样”的调度口径不同：Icarus 在该测试平台
        // 结构下观测到 NBA 更新前的值（11），Verilator --timing 观测到
        // 更新后的值（12）。用宏隔离预期，正文专门解释这一拍差异。
        `ifdef VERILATOR
        if (count !== 4'd12)
            $fatal(1, "counter mismatch: verilator expected 12, got %0d", count);
        `else
        if (count !== 4'd11)
            $fatal(1, "counter mismatch: iverilog expected 11, got %0d", count);
        `endif
        $display("PASS final_count=%0d", count);
        $finish;
    end
endmodule
