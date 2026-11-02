`timescale 1ns/1ps
// 用例 1：异步复位必须把 q 清成 0（仿真中途再次拉低复位也要清）
module tb_reset;
    reg clk = 0, rst_n = 0, en = 1;
    wire [3:0] q;
    wire       carry;
    counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
    always #5 clk = ~clk;

    integer errors = 0;
    initial begin
        #17;
        if (q !== 4'd0) begin
            errors = errors + 1;
            $display("power-on reset: q=%h expect 0", q);
        end
        rst_n = 1;
        #40;                 // 让计数器先数几拍
        rst_n = 0;
        #12;
        if (q !== 4'd0) begin
            errors = errors + 1;
            $display("mid-run reset: q=%h expect 0", q);
        end
        if (carry !== 1'b0) errors = errors + 1;

        if (errors == 0) $display("TEST PASS tb_reset");
        else             $display("TEST FAIL tb_reset errors=%0d", errors);
        $finish;
    end
endmodule
