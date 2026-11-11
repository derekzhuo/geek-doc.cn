`timescale 1ns/1ps

module check_dff(input wire clk, input wire d, output reg q);
    always @(posedge clk)
        q <= d;

    specify
        $setup(d, posedge clk, 4);
        $hold(posedge clk, d, 3);
    endspecify
endmodule

module tb_timing;
    reg clk;
    reg d;
    wire q;

    check_dff dut(.clk(clk), .d(d), .q(q));

    initial begin
        clk = 1'b0;
        d = 1'b0;

        #1 d = 1'b1;
        #1 clk = 1'b1;
        $display("TIMING case=setup_violation t=%0t d=%b clk=%b q=%b", $time, d, clk, q);
        #1 $display("TIMING case=setup_sampled t=%0t d=%b clk=%b q=%b", $time, d, clk, q);

        #2 clk = 1'b0;
        #2 d = 1'b0;
        #1 clk = 1'b1;
        #1 d = 1'b1;
        $display("TIMING case=hold_violation t=%0t d=%b clk=%b q=%b", $time, d, clk, q);

        #4 clk = 1'b0;
        #4 clk = 1'b1;
        $display("TIMING case=clean_edge t=%0t d=%b clk=%b q=%b", $time, d, clk, q);
        #4 d = 1'b0;
        $display("TIMING case=clean_hold t=%0t d=%b clk=%b q=%b", $time, d, clk, q);
        $finish;
    end
endmodule
