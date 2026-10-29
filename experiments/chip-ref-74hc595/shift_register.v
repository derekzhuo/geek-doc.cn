`timescale 1ns/1ps
module shift_74hc595 (
    input  wire       ds,
    input  wire       shcp,
    input  wire       stcp,
    input  wire       mr_n,
    input  wire       oe_n,
    output wire [7:0] q,
    output wire       q7s
);
    reg [7:0] shift_reg;
    reg [7:0] latch_reg;
    assign q = oe_n ? 8'hzz : latch_reg;
    assign q7s = shift_reg[7];

    always @(posedge shcp or negedge mr_n) begin
        if (!mr_n)
            shift_reg <= 8'h00;
        else
            shift_reg <= {shift_reg[6:0], ds};
    end

    always @(posedge stcp or negedge mr_n) begin
        if (!mr_n)
            latch_reg <= 8'h00;
        else
            latch_reg <= shift_reg;
    end
endmodule
