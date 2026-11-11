module counter #(parameter W=8) (
    input  wire          clk,
    input  wire          rst_n,
    output reg  [W-1:0]  cnt,
    output wire          co
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= {W{1'b0}};
        else        cnt <= cnt + 1'b1;
    end
    assign co = (cnt == {W{1'b1}});
endmodule
