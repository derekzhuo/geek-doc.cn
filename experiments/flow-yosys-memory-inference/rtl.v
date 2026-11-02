// 三种数组写法对照：用于观察 Yosys 存储器推断各阶段的 stat
// 全部 16x8，变量名统一为 mem，便于横向比较

// 写法 A：规则数组 —— 同步写 + 同步读（输出寄存），综合 RAM 标准模板
// 另带 initial 初值，观察 $mem 的 init 数据如何被保留
module ram_sync (
    input        clk,
    input        we,
    input  [3:0] waddr,
    input  [3:0] raddr,
    input  [7:0] wdata,
    output reg [7:0] rdata
);
    reg [7:0] mem [0:15];

    initial begin
        mem[0] = 8'h5A;
    end

    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata;
        rdata <= mem[raddr];
    end
endmodule

// 写法 B：同步写 + 异步读（连续赋值直接引出）
// 仍可推断成 $mem，但读口没有时钟，通用流程最终只能摊成 DFF + 选择树
module ram_async (
    input        clk,
    input        we,
    input  [3:0] waddr,
    input  [3:0] raddr,
    input  [7:0] wdata,
    output [7:0] rdata
);
    reg [7:0] mem [0:15];

    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule

// 写法 C：会被摊平的写法 —— 组合 always 块里异步写数组（无时钟沿）
// memory_collect 放弃推断，前端直接 Warning 并替换成一串寄存器
module ram_flat (
    input        we,
    input  [3:0] addr,
    input  [7:0] wdata,
    output [7:0] rdata
);
    reg [7:0] mem [0:15];

    always @(*) begin
        if (we) mem[addr] = wdata;
    end

    assign rdata = mem[addr];
endmodule
