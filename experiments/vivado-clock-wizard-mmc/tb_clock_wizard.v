`timescale 1ns/1ps
module tb_clock_wizard;
reg clk100 = 0;
reg reset = 1;
wire clk50;
wire clk200;
wire locked;
wire [7:0] count50;
wire [7:0] count200;
real t0;
real elapsed50;
real elapsed200;

clock_top dut (
    .clk100(clk100), .reset(reset),
    .clk50(clk50), .clk200(clk200), .locked(locked),
    .count50(count50), .count200(count200)
);
always #5 clk100 = ~clk100;

initial begin
    repeat (4) @(posedge clk100);
    #1 reset = 0;
    wait (locked === 1'b1);
    if ($realtime > 1500) begin
        $display("CLOCK_WIZ_LOCK_FAIL locked_time_ns=%f", $realtime);
        $fatal(1);
    end
    $display("CLOCK_WIZ_LOCKED time_ns=%f", $realtime);
    @(posedge clk50);
    t0 = $realtime;
    repeat (20) @(posedge clk50);
    elapsed50 = $realtime - t0;
    if (elapsed50 < 399.999 || elapsed50 > 400.001) begin
        $display("CLOCK_WIZ_FREQ_FAIL output=clk50 elapsed_ns=%f", elapsed50);
        $fatal(1);
    end
    @(posedge clk200);
    t0 = $realtime;
    repeat (20) @(posedge clk200);
    elapsed200 = $realtime - t0;
    if (elapsed200 < 99.999 || elapsed200 > 100.001) begin
        $display("CLOCK_WIZ_FREQ_FAIL output=clk200 elapsed_ns=%f", elapsed200);
        $fatal(1);
    end
    $display("CLOCK_WIZ_PASS clk50_period_ns=%f clk200_period_ns=%f", elapsed50 / 20.0, elapsed200 / 20.0);
    $finish;
end
endmodule
