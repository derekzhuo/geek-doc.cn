// Self-checking TB for counter16.
`timescale 1ns/1ps
module tb_counter16;
    reg clk = 0, rst_n = 0, en = 0;
    wire [15:0] count;
    wire tc;

    counter16 dut (.clk(clk), .rst_n(rst_n), .en(en), .count(count), .tc(tc));
    always #5 clk = ~clk;

    integer errors = 0;
    integer i;
    initial begin
        $dumpfile("sim/counter16.vcd");
        $dumpvars(0, tb_counter16);
        repeat (3) @(posedge clk);
        rst_n <= 1;
        @(negedge clk);
        en <= 1;
        for (i = 0; i < 200; i = i + 1) begin
            @(posedge clk); #1;
            if (count !== ((i + 1) & 16'hFFFF)) begin
                errors = errors + 1;
                $display("[%0t] ERROR count=%0d expect=%0d", $time, count, i + 1);
            end
        end
        // enable gating check
        en <= 0;
        repeat (5) @(posedge clk);
        #1;
        if (count !== 16'd200) begin
            errors = errors + 1;
            $display("enable gating broken: count=%0d", count);
        end
        $display("errors=%0d", errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
