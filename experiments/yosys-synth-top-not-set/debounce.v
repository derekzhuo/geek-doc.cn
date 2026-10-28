// 按键消抖：计数器式滤波
module debounce (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);
    reg [15:0] cnt;
    reg        sync_0, sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {sync_1, sync_0} <= 2'b00;
            cnt              <= 16'd0;
            dout             <= 1'b0;
        end else begin
            {sync_1, sync_0} <= {sync_0, din};
            if (sync_1 == dout) begin
                cnt <= 16'd0;
            end else begin
                cnt <= cnt + 16'd1;
                if (cnt == 16'hffff)
                    dout <= sync_1;
            end
        end
    end
endmodule
