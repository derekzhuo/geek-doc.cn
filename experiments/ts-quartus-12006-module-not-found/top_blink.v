// Top level: instantiates sub_divider, whose source file is deliberately
// omitted from the probe project's VERILOG_FILE list to reproduce the
// real "module/entity not found" error code on Quartus Prime Lite 25.1.
module top_blink (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);
    wire tick;

    sub_divider #(
        .WIDTH(24)
    ) u_div (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led <= 1'b0;
        else if (tick)
            led <= ~led;
    end
endmodule
