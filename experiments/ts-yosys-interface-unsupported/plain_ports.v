module counter(
    input  wire       clk,
    input  wire       req,
    output reg  [7:0] data
);
    initial data = 8'd0;

    always @(posedge clk) begin
        if (req)
            data <= data + 1'b1;
    end
endmodule
