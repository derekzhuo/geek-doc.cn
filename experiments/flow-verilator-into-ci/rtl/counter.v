// 8-bit counter with async reset, enable and parallel load (CI demo DUT)
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       load,
    input  wire [7:0] din,
    output reg  [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'd0;
        else if (load)
            q <= din;
        else if (en)
            q <= q + 8'd1;
    end
endmodule
