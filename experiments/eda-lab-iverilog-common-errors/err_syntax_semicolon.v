// 错误1：语法错误——always 块里赋值语句漏分号
module counter (
    input  wire clk,
    input  wire rst_n,
    output reg  [7:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 8'd0   // <-- 这里漏了分号
        else
            cnt <= cnt + 8'd1;
    end
endmodule
