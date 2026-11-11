`timescale 1ns/1ps
// Bad testbench: start is declared but never driven, so it holds X for the
// whole run. The wait() can never resume and the watchdog has to end the sim.
module tb_xhang_bad;
    reg clk;
    reg rst_n;
    reg start;          // no initial value, no assignment anywhere -> X
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
        #13 rst_n = 1'b1;
        wait (start === 1'b1);
        $display("GO observed at %0t ns, state=%0d", $time, state);
        #50 $finish;
    end

    initial begin
        #500;
        $display("watchdog: start=%b is_x=%0d state=%0d at %0t ns",
                 start, (start === 1'bx), state, $time);
        $finish;
    end
endmodule
