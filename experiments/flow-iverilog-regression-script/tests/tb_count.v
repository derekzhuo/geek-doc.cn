`timescale 1ns/1ps
// 用例 2：复位释放后，使能拉高期间每个时钟沿加一；使能拉低后保持
module tb_count;
    reg clk = 0, rst_n = 0, en = 0;
    wire [3:0] q;
    wire       carry;
    counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
    always #5 clk = ~clk;

    integer errors = 0;
    initial begin
        #23 rst_n = 1;
        #3  en    = 1;              // 在两个沿之间拉高，避免沿上驱动竞争
        repeat (6) @(posedge clk);   // 6 个使能沿（35ns 起）
        #1; en = 0;                  // 沿后再拉低，避开沿上竞争
        repeat (2) @(posedge clk);   // 停使能再走两拍
        #1;
        if (q !== 4'd6) begin
            errors = errors + 1;
            $display("count/hold: q=%0d expect 6", q);
        end

        if (errors == 0) $display("TEST PASS tb_count");
        else             $display("TEST FAIL tb_count errors=%0d", errors);
        $finish;
    end
endmodule
