module top (
    input clk
);
    reg [3:0] a = 0;
    reg [3:0] b = 0;
    always @(posedge clk) begin
        a <= a + 4'd1;
        b <= b + 4'd1;
        assert(a == b);
    end
endmodule
