// TB for two-flop synchronizer: toggle async input near clock edges,
// log per-cycle samples of d_async / meta / q_sync.
// PASS = q_sync stably follows d_async within 3 destination clocks after each toggle.
`timescale 1ns/1ps
module tb_sync_2ff;
    reg clk = 0;
    reg rst_n = 0;
    reg d_async = 0;
    wire q_sync;

    sync_2ff dut (.clk(clk), .rst_n(rst_n), .d_async(d_async), .q_sync(q_sync));

    always #5 clk = ~clk;   // 100 MHz destination clock

    integer errors = 0;
    integer checks = 0;

    // per-cycle sample log
    always @(posedge clk) begin
        #1;
        $display("[%0t] sample d_async=%b meta=%b q_sync=%b",
                 $time, d_async, dut.meta, q_sync);
    end

    // after each toggle, wait 3 clocks then require q_sync == d_async
    task toggle_and_check;
        input integer delay_ps;
        input val;
        begin
            #(delay_ps / 1000.0) d_async = val;   // toggle off-edge (ns units)
            $display("[%0t] TOGGLE d_async -> %b (async, off clock edge)", $time, val);
            repeat (3) @(posedge clk);
            #1;
            checks = checks + 1;
            if (q_sync !== val) begin
                errors = errors + 1;
                $display("[%0t] ERROR: q_sync=%b still not following d_async=%b after 3 clocks",
                         $time, q_sync, val);
            end else begin
                $display("[%0t] OK: q_sync followed d_async=%b within 3 clocks", $time, val);
            end
        end
    endtask

    initial begin
        $dumpfile("sync_2ff.vcd");
        $dumpvars(0, tb_sync_2ff);
        repeat (3) @(posedge clk);
        rst_n <= 1;
        @(posedge clk);

        // toggles deliberately offset from the clock edge (7, 3, 9, 1 ns)
        toggle_and_check(7000, 1'b1);
        toggle_and_check(3000, 1'b0);
        toggle_and_check(9000, 1'b1);
        toggle_and_check(1000, 1'b0);
        toggle_and_check(7000, 1'b1);

        repeat (4) @(posedge clk);
        $display("checks=%0d errors=%0d", checks, errors);
        if (errors == 0 && checks == 5) $display("RESULT: PASS");
        else                            $display("RESULT: FAIL");
        $finish;
    end
endmodule
