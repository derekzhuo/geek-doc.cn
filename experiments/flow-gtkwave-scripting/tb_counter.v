`timescale 1ns/1ps
module tb_counter;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [7:0] cnt;
    wire       co;

    always #5 clk = ~clk;   // 10ns period

    counter dut (.clk(clk), .rst_n(rst_n), .cnt(cnt), .co(co));

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_counter);
        #12  rst_n = 1'b1;
        #200 $finish;
    end
endmodule
