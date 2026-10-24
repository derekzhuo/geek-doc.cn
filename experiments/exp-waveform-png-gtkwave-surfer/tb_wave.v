// Simple traffic for waveform export demo: counter + handshake pulses.
`timescale 1ns/1ps
module tb_wave;
    reg clk = 0, rst_n = 0;
    reg req = 0;
    reg ack = 0;
    reg [3:0] cnt = 0;

    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (!rst_n) cnt <= 0;
        else        cnt <= cnt + 1;
    end

    initial begin
        $dumpfile("wave_demo.vcd");
        $dumpvars(0, tb_wave);
        repeat (3) @(posedge clk);
        rst_n <= 1;
        // a couple of req/ack handshake pulses
        repeat (2) begin
            @(negedge clk); req <= 1;
            repeat (2) @(negedge clk); ack <= 1;
            @(negedge clk); req <= 0;
            @(negedge clk); ack <= 0;
        end
        repeat (4) @(posedge clk);
        $display("RESULT: SIMDONE");
        $finish;
    end
endmodule
