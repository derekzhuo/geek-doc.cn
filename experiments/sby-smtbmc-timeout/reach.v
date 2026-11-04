// assert form: violation only reachable after cnt hits 10 (cycle ~11)
module top (
    input clk
);
    reg [3:0] cnt = 0;
    always @(posedge clk) begin
        cnt <= cnt + 4'd1;
        assert(cnt != 4'd10);
    end
endmodule
