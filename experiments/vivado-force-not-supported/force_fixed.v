// FIXED: express the override intent with an enable mux inside one always block.
module force_fixed (
    input  wire clk,
    input  wire rstn,
    input  wire d,
    input  wire override_en,
    output reg  q
);
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q <= 1'b0;
        else if (override_en)
            q <= 1'b1;
        else
            q <= d;
    end
endmodule
