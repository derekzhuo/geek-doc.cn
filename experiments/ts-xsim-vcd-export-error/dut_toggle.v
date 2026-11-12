`timescale 1ns/1ps
// Simple toggling counter giving the waveform dump something to record.
module dut_toggle (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd0;
        else
            cnt <= cnt + 4'd1;
    end
endmodule
