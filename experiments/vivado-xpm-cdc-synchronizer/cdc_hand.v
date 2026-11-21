`timescale 1ns/1ps

module cdc_hand (
    input wire src_clk,
    input wire src_in,
    input wire dest_clk,
    output wire dest_out
);
(* ASYNC_REG = "TRUE" *) reg sync1 = 1'b0;
(* ASYNC_REG = "TRUE" *) reg sync2 = 1'b0;
always @(posedge dest_clk) begin
    sync1 <= src_in;
    sync2 <= sync1;
end
assign dest_out = sync2;
endmodule
