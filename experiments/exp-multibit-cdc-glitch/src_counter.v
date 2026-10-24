// 4-bit counter in source clock domain (the CDC producer).
module src_counter (
    input  wire       src_clk,
    input  wire       rst_n,
    output reg  [3:0] bus
);
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) bus <= 4'd0;
        else        bus <= bus + 4'd1;
    end
endmodule
