// 毛刺滤波器：一个没被 chip_top 例化的「孤儿」模块
// 常见来源：早期版本的遗留模块 / 从别的工程拷来的工具模块
module glitch_filter (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);
    reg [2:0] hist;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hist <= 3'b000;
            dout <= 1'b0;
        end else begin
            hist <= {hist[1:0], din};
            dout <= &hist | (|hist & dout);
        end
    end
endmodule
