// tb_counter.v —— 计数器自检 testbench（激励在下降沿驱动，避免调度竞态）
`timescale 1ns/1ps
module tb_counter;
    parameter WIDTH = 8;
    parameter SEED = 1;

    reg  clk = 1'b0;
    reg  rst_n = 1'b0;
    reg  en = 1'b0;
    wire [WIDTH-1:0] count;

    counter #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .count(count)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    initial begin
        $display("[tb] WIDTH=%0d SEED=%0d start", WIDTH, SEED);
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        if (count !== 0) begin
            $display("[tb] FAIL: count=%0d after reset, expect 0", count);
            errors = errors + 1;
        end
        en = 1'b1;
        repeat (10) @(negedge clk);
        if (count !== 10) begin
            $display("[tb] FAIL: count=%0d after 10 cycles, expect 10", count);
            errors = errors + 1;
        end
        en = 1'b0;
        repeat (4) @(negedge clk);
        if (count !== 10) begin
            $display("[tb] FAIL: count=%0d changed while en=0", count);
            errors = errors + 1;
        end
        if (errors == 0)
            $display("[tb] PASS: all checks passed (WIDTH=%0d)", WIDTH);
        else
            $display("[tb] FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
