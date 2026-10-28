module selrange_fixed (
    input  wire [7:0] data,
    input  wire [3:0] idx,
    output wire       bit_const,
    output wire       bit_var,
    output wire [3:0] nibble
);
    // 常量下标改回合法范围
    assign bit_const = data[7];

    // 可变下标先判断范围，越界时给默认值 0
    assign bit_var = (idx < 8) ? data[idx[2:0]] : 1'b0;

    // 部分选择改回 [7:4]
    assign nibble = data[7:4];
endmodule
