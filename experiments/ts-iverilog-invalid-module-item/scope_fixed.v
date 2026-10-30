`timescale 1ns/1ps
module scope_fixed (
    input  wire a,
    output reg  y
);
    always @* begin
        if (a) begin
            y = 1'b1;
        end else begin
            y = 1'b0;
        end
    end
endmodule
