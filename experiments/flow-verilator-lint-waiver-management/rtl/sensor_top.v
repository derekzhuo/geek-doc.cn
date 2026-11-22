// sensor_top.v -- 传感器采样顶层（历史模块，寄存器映射沿用老协议）
// 16 位采样数据按协议只把低 8 位映射进 8 位上报寄存器，高 8 位留给未实现的调试接口。
module sensor_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_en,
    input  wire [15:0] sample_data,
    output wire [7:0]  status,
    output wire        tick
);
    wire       baud_tick;
    reg [15:0] hold;

    baud_tick u_baud_tick (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (sample_en),
        .tick  (baud_tick)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hold <= 16'd0;
        else if (baud_tick)
            hold <= sample_data;
    end

    // 协议规定上报寄存器只有 8 位，16 位保持值整体接入，按 Verilog 语义截取低字节
    assign status = hold;

    // 历史保留信号：高字节预留给未实现的调试接口，当前版本无人消费
    wire [7:0] spare_high;
    assign spare_high = hold[15:8];

    assign tick = baud_tick;
endmodule
