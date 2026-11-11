// CRC16 模板：POLY/INIT/REFLECT 可参数化
// REFLECT=0：MSB-first，CRC-16/CCITT-FALSE（POLY=16'h1021, INIT=16'hFFFF）
// REFLECT=1：LSB-first 输入反射，CRC-16/ARC（POLY=16'h8005, INIT=16'h0000）
module crc16_serial #(
    parameter logic [15:0] POLY    = 16'h1021,
    parameter logic [15:0] INIT    = 16'hFFFF,
    parameter bit          REFLECT = 1'b0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bit_valid,
    input  wire        bit_data,
    output logic [15:0] crc
);
    // 反射 LFSR 用位反转后的工作多项式（0x8005 -> 16'hA001）
    function automatic logic [15:0] rev16(input logic [15:0] x);
        logic [15:0] r;
        for (int k = 0; k < 16; k++) r[k] = x[15-k];
        return r;
    endfunction
    localparam logic [15:0] WPOLY = REFLECT ? rev16(POLY) : POLY;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc <= INIT;
        else if (bit_valid) begin
            if (!REFLECT) begin
                // MSB-first：反馈看最高位
                if (crc[15] ^ bit_data)
                    crc <= {crc[14:0], 1'b0} ^ WPOLY;
                else
                    crc <= {crc[14:0], 1'b0};
            end else begin
                // LSB-first：反馈看最低位，右移
                if (crc[0] ^ bit_data)
                    crc <= {1'b0, crc[15:1]} ^ WPOLY;
                else
                    crc <= {1'b0, crc[15:1]};
            end
        end
    end
endmodule

// 字节级并行：1 拍处理一个字节（内部展开 8 次）
module crc16_parallel #(
    parameter logic [15:0] POLY    = 16'h1021,
    parameter logic [15:0] INIT    = 16'hFFFF,
    parameter bit          REFLECT = 1'b0
)(
    input  wire [7:0]  data_in,
    input  wire [15:0] crc_in,
    output logic [15:0] crc_out
);
    // 字节位反转（反射输入用）
    function automatic logic [7:0] rev8(input logic [7:0] x);
        logic [7:0] r;
        for (int k = 0; k < 8; k++) r[k] = x[7-k];
        return r;
    endfunction
    function automatic logic [15:0] rev16(input logic [15:0] x);
        logic [15:0] r;
        for (int k = 0; k < 16; k++) r[k] = x[15-k];
        return r;
    endfunction
    localparam logic [15:0] WPOLY = REFLECT ? rev16(POLY) : POLY;

    always_comb begin
        logic [15:0] c;
        logic [7:0]  d;
        logic fb;
        c = crc_in;
        d = REFLECT ? rev8(data_in) : data_in;
        for (int i = 7; i >= 0; i--) begin
            if (!REFLECT) begin
                fb = c[15] ^ d[i];
                c  = {c[14:0], 1'b0};
                if (fb) c = c ^ WPOLY;
            end else begin
                fb = c[0] ^ d[i];
                c  = {1'b0, c[15:1]};
                if (fb) c = c ^ WPOLY;
            end
        end
        crc_out = c;
    end
endmodule
