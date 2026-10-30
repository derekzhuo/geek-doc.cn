module immediate_assert (
    input  wire clk,
    input  wire valid,
    input  wire ready,
    output reg  seen
);
    initial seen = 1'b0;

    always @(posedge clk) begin
        if (valid) begin
            seen <= 1'b1;
            assert (ready);
        end
    end
endmodule
