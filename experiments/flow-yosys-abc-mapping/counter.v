// 8-bit enable counter with asynchronous active-low reset and carry-out
module counter #(
    parameter W = 8
) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    output reg  [W-1:0]  q,
    output wire          carry
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {W{1'b0}};
        else if (en)
            q <= q + 1'b1;
    end

    assign carry = en & (q == {W{1'b1}});
endmodule
