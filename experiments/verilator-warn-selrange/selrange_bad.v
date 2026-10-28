module selrange_bad (
    input  wire [7:0] data,
    input  wire [3:0] idx,
    output wire       bit_const,
    output wire       bit_var,
    output wire [3:0] nibble
);
    // 常量下标越界：8 位向量合法下标是 [7:0]，取第 8 位超界
    assign bit_const = data[8];

    // 可变下标可能越界：idx 范围 0~15，data 只有 0~7
    assign bit_var = data[idx];

    // 部分选择越界：从 6 开始取 4 位，最高到 9
    assign nibble = data[9:6];
endmodule
