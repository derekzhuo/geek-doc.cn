`timescale 1ns/1ps

module cdc_xpm (
    input wire src_clk,
    input wire src_in,
    input wire dest_clk,
    output wire dest_out
);
xpm_cdc_single #(
    .DEST_SYNC_FF(2),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(1),
    .SRC_INPUT_REG(0)
) sync_inst (
    .src_clk(src_clk),
    .src_in(src_in),
    .dest_clk(dest_clk),
    .dest_out(dest_out)
);
endmodule
