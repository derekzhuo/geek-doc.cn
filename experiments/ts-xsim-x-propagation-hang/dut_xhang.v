`timescale 1ns/1ps
// Counter gated by an external start strobe. The DUT is correct; whether the
// simulation progresses depends entirely on the testbench driving start to a
// known 0/1 value. An undriven start stays X and the ===1 check never matches.
module dut_xhang (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    output reg  [3:0] state
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 4'd0;
        else if (start === 1'b1)
            state <= state + 4'd1;
    end
endmodule
