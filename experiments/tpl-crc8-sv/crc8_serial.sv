// CRC8 逐位（bit-serial）模板：每个时钟处理 1 个比特，8 拍处理完 1 字节
// POLY/INIT 可参数化；默认 POLY=8'h07、INIT=8'h00，对应 CRC-8/SMBUS
module crc8_serial #(
    parameter logic [7:0] POLY = 8'h07,
    parameter logic [7:0] INIT = 8'h00
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       bit_valid,   // 高电平期间在上升沿吃掉 1 个比特
    input  wire       bit_data,    // MSB 先送
    output logic [7:0] crc
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc <= INIT;
        else if (bit_valid) begin
            // 标准 MSB-first 反馈：最高位与输入异或后决定是否反馈多项式
            if (crc[7] ^ bit_data)
                crc <= {crc[6:0], 1'b0} ^ POLY;
            else
                crc <= {crc[6:0], 1'b0};
        end
    end
endmodule

// CRC8 并行（字节级）模板：1 拍处理完整个字节，组合逻辑把 8 次移位异或展开
module crc8_parallel #(
    parameter logic [7:0] POLY = 8'h07,
    parameter logic [7:0] INIT = 8'h00
)(
    input  wire [7:0] data_in,
    input  wire [7:0] crc_in,
    output logic [7:0] crc_out
);
    always_comb begin
        logic [7:0] c;
        logic fb;
        c = crc_in;
        for (int i = 7; i >= 0; i--) begin
            fb = c[7] ^ data_in[i];
            c = {c[6:0], 1'b0};
            if (fb) c = c ^ POLY;
        end
        crc_out = c;
    end
endmodule
