// undriven_fixed.v -- 修复：把同步寄存器补回来，data_sync 有了明确驱动源
module undriven_fixed (
    input  wire       clk,
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_sync;

    always @(posedge clk) begin
        data_sync <= data_in;
    end

    assign data_out = data_sync & 8'hFF;

endmodule
