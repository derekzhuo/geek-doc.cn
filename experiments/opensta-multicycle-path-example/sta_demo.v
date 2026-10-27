// sta_demo.v — simple counter used as STA timing target
module sta_demo (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [7:0] q
);
    always @(posedge clk) begin
        if (!rst_n) q <= 8'h00;
        else if (en) q <= q + 1;
    end
endmodule
