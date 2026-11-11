// 4-bit loadable counter with synchronous active-low reset and enable.
// q increments when en=1; load=1 takes priority and copies din.
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       load,
    input  wire [3:0] din,
    output reg  [3:0] q
);

always @(posedge clk) begin
    if (!rst_n)
        q <= 4'd0;
    else if (load)
        q <= din;
    else if (en)
        q <= q + 4'd1;
end

endmodule
