// counter_no_ts.v —— 坑 1 复现素材：counter 的「忘写 `timescale」版本。
// 与带 timescale 的 counter_tb.v 一起编译时，verilator 报 TIMESCALEMOD 并退出。
module counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output reg  [31:0] count
);
    always @(posedge clk) begin
        if (!rst_n)  count <= 32'd0;
        else if (en) count <= count + 32'd1;
    end
endmodule
