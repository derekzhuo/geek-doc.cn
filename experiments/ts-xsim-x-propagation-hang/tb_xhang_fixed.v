`timescale 1ns/1ps
// Fixed testbench: start is held low through reset and pulsed from a
// separate initial block. The wait() resumes on the real strobe and the
// sim finishes well before the watchdog window.
module tb_xhang_fixed;
    reg clk;
    reg rst_n;
    reg start;
    wire [3:0] state;

    dut_xhang dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .state(state)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        #13 rst_n = 1'b1;
        wait (start === 1'b1);
        $display("GO observed at %0t ns, state=%0d", $time, state);
        #50 $finish;
    end

    initial begin
        @(posedge rst_n);
        repeat (2) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
    end

    initial begin
        #500;
        $display("watchdog: start=%b is_x=%0d state=%0d at %0t ns",
                 start, (start === 1'bx), state, $time);
        $finish;
    end
endmodule
