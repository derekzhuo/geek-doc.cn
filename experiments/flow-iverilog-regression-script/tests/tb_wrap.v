`timescale 1ns/1ps
// 用例 3：数到 15 时 carry 拉高一拍，下一拍 q 回卷成 0
module tb_wrap;
    reg clk = 0, rst_n = 0, en = 0;
    wire [3:0] q;
    wire       carry;
    counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
    always #5 clk = ~clk;

    integer errors = 0;
    initial begin
        #23 rst_n = 1;
        #3  en    = 1;              // 在两个沿之间拉高，避免沿上驱动竞争
        repeat (15) @(posedge clk);  // q == 15
        #1;
        if (q !== 4'd15) begin
            errors = errors + 1;
            $display("pre-wrap: q=%0d expect 15", q);
        end
        @(posedge clk);              // 第 16 个使能沿
        #1;
        if (carry !== 1'b1) begin
            errors = errors + 1;
            $display("wrap: carry=%b expect 1", carry);
        end
        if (q !== 4'd0) begin
            errors = errors + 1;
            $display("wrap: q=%0d expect 0", q);
        end

        if (errors == 0) $display("TEST PASS tb_wrap");
        else             $display("TEST FAIL tb_wrap errors=%0d", errors);
        $finish;
    end
endmodule
