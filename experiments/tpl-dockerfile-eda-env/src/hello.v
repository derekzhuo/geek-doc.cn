// 冒烟用最小 RTL：带复位的 4 位计数器，iverilog 仿真 + verilator lint + yosys 综合共用
module hello (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd0;
        else
            cnt <= cnt + 4'd1;
    end
endmodule
