// undriven_bad.v -- 复现 Yosys check 报的 undriven signal 警告
// 场景：data_sync 原本是打两拍的同步链，重构时删掉了寄存器逻辑，
// 但声明和下游消费语句留了下来，信号悬空没有任何驱动源。
module undriven_bad (
    input  wire       clk,
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);

    wire [7:0] data_sync;   // 声明了，但没有任何 assign/寄存器驱动它

    assign data_out = data_sync & 8'hFF;

    always @(posedge clk) begin
        // 其他逻辑略
    end

endmodule
