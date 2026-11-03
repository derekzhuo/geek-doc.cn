// 给 yosys tcl 控制流演示用的小模块之二
module cnt4 (
    input  wire       clk,
    input  wire       rst,
    output reg [3:0]  q
);
    always @(posedge clk) begin
        if (rst) q <= 4'd0;
        else     q <= q + 4'd1;
    end
endmodule
