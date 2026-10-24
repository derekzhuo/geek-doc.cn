// Style A: plain clock-enable register (mux feedback before the DFF).
module reg_en (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)  q <= 8'd0;
        else if (en) q <= d;
    end
endmodule
