`timescale 1ns/1ps

module scoreboard_dut (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       in_valid,
    input  logic [7:0] in_data,
    output logic       out_valid,
    output logic [7:0] out_data
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= 8'h00;
        end else begin
            out_valid <= in_valid;
            out_data  <= in_data;
        end
    end
endmodule
