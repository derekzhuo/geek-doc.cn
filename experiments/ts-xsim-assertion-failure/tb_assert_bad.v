`timescale 1ns/1ps
// Bad checker: the bound is hard-coded to 9 even though a 4-bit counter
// legitimately wraps through 15. $fatal fires on the first cnt == 10.
module tb_assert_bad;
    reg        clk   = 0;
    reg        rst_n = 0;
    reg        en    = 1;
    wire [3:0] cnt;

    dut_counter u_dut (
        .clk(clk), .rst_n(rst_n), .en(en), .cnt(cnt)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && cnt >= 4'd10)
            $fatal(1, "bound check failed: cnt=%0d exceeded 9", cnt);
    end

    initial begin
        #12 rst_n = 1;
        #200 $finish;
    end
endmodule
