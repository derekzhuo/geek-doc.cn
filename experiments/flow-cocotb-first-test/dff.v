// Minimal DUT for the first cocotb test: an active-low async-reset D flip-flop.
module dff (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q <= 1'b0;
    else
        q <= d;
end

endmodule
