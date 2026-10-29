`timescale 1ns/1ps
module counter_cd4017 (
    input  wire       clk,
    input  wire       reset,
    input  wire       clock_enable_n,
    output reg  [9:0] q,
    output wire       carry_n
);
    assign carry_n = ~(q[0] | q[1] | q[2] | q[3] | q[4]);

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 10'b00000_00001;
        else if (!clock_enable_n) begin
            if (q[9])
                q <= 10'b00000_00001;
            else
                q <= q << 1;
        end
    end
endmodule
