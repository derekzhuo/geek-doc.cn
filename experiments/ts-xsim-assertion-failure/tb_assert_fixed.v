`timescale 1ns/1ps
// Fixed checker: a 4-bit counter's legal range is 0..15, so the bound
// matches the bus width. The assertion never fires and the run reaches $finish.
module tb_assert_fixed;
    reg        clk   = 0;
    reg        rst_n = 0;
    reg        en    = 1;
    wire [3:0] cnt;

    dut_counter u_dut (
        .clk(clk), .rst_n(rst_n), .en(en), .cnt(cnt)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && cnt > 4'd15)
            $fatal(1, "out of 4-bit range: cnt=%0d", cnt);
    end

    initial begin
        #12 rst_n = 1;
        #200 $finish;
    end
endmodule
