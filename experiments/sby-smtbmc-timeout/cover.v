// cover form: goal state cnt==10 first reachable at step 11
module top (
    input clk
);
    reg [3:0] cnt = 0;
    always @(posedge clk) begin
        cnt <= cnt + 4'd1;
        cover(cnt == 4'd10);
    end
endmodule
