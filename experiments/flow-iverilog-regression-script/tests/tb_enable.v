`timescale 1ns/1ps
// 用例 4：使能为 0 时值保持不变
module tb_enable;
    reg clk = 0, rst_n = 0, en = 0;
    wire [3:0] q;
    wire       carry;
    counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
    always #5 clk = ~clk;

    integer errors = 0;
    initial begin
        #23 rst_n = 1;
        #3  en    = 1;              // 在两个沿之间拉高，避免沿上驱动竞争
        repeat (3) @(posedge clk);   // q == 3（35/45/55ns 三个沿）
        #1; en = 0;                  // 沿后再拉低，避开沿上竞争
        repeat (4) @(posedge clk);   // 停四个沿，应保持 3
        #1;
        if (q !== 4'd3) begin        // 停使能期间必须保持 3
            errors = errors + 1;
            $display("enable-hold: q=%0d expect 3", q);
        end

        if (errors == 0) $display("TEST PASS tb_enable");
        else             $display("TEST FAIL tb_enable errors=%0d", errors);
        $finish;
    end
endmodule
