`timescale 1ns/1ps

module fsm_onehot (
    input wire clk,
    input wire rst,
    input wire go,
    output reg [6:0] grant
);
localparam IDLE=8'b00000001, S0=8'b00000010, S1=8'b00000100, S2=8'b00001000;
localparam S3=8'b00010000, S4=8'b00100000, S5=8'b01000000, S6=8'b10000000;
(* fsm_encoding = "one_hot" *) reg [7:0] state;
always @(posedge clk) begin
    if (rst) state <= IDLE;
    else if (go) begin
        case (state)
            IDLE: state <= S0; S0: state <= S1; S1: state <= S2; S2: state <= S3;
            S3: state <= S4; S4: state <= S5; S5: state <= S6; default: state <= IDLE;
        endcase
    end
end
always @* begin
    case (state)
        S0: grant=7'b0000001; S1: grant=7'b0000010; S2: grant=7'b0000100;
        S3: grant=7'b0001000; S4: grant=7'b0010000; S5: grant=7'b0100000;
        S6: grant=7'b1000000; default: grant=7'b0000000;
    endcase
end
endmodule
