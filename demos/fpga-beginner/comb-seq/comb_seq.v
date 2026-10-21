// comb_seq.v —— 组合逻辑 vs 时序逻辑的可综合写法对照
// 配套 fpga/beginner/06-verilog-combinational-sequential.md
//
// 上半部分（mux4 / decoder_3to8）是组合逻辑：
//   - assign 连续赋值，或 always @(*) 块
//   - 用阻塞赋值 =
//   - 输出只取决于当前输入，没有记忆、没有时钟
// 下半部分（reg_en / counter_en）是时序逻辑：
//   - always @(posedge clk) 块
//   - 用非阻塞赋值 <=
//   - 有寄存器（记忆），状态只在时钟沿更新，通常带复位

// ========== 组合逻辑 ==========

// 1) 4 选 1 多路选择器：assign + 三目，最直观的组合写法
module mux4 (
    input  wire [3:0] d,
    input  wire [1:0] sel,
    output wire       y
);
    assign y = (sel == 2'd0) ? d[0] :
               (sel == 2'd1) ? d[1] :
               (sel == 2'd2) ? d[2] : d[3];
endmodule

// 2) 3-8 译码器：always @(*) + case
//    关键：开头先给 y 一个默认值，保证任何输入路径下输出都被赋值 -> 不会推断出锁存器
module decoder_3to8 (
    input  wire [2:0] in,
    output reg  [7:0] y
);
    always @(*) begin
        y = 8'b0000_0000;          // 默认输出（也可改用 case 里的 default，二选一即可）
        case (in)
            3'd0: y = 8'b0000_0001;
            3'd1: y = 8'b0000_0010;
            3'd2: y = 8'b0000_0100;
            3'd3: y = 8'b0000_1000;
            3'd4: y = 8'b0001_0000;
            3'd5: y = 8'b0010_0000;
            3'd6: y = 8'b0100_0000;
            3'd7: y = 8'b1000_0000;
            default: y = 8'b0000_0000;
        endcase
    end
endmodule

// ========== 时序逻辑 ==========

// 3) 带使能的数据寄存器（一组 D 触发器）
//    异步复位、低有效；en=1 时在时钟沿载入 d，en=0 时保持
module reg_en #(
    parameter W = 8
) (
    input  wire          clk,
    input  wire          rst_n,   // 低有效复位
    input  wire          en,
    input  wire [W-1:0]  d,
    output reg  [W-1:0]  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {W{1'b0}};        // 复位清 0
        else if (en)
            q <= d;                // 使能时载入；没写 else => en=0 自动保持
    end
endmodule

// 4) 带使能的加法计数器，数到 MAX 回卷
module counter_en #(
    parameter W   = 4,
    parameter MAX = 4'd9
) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    output reg  [W-1:0]  cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= {W{1'b0}};
        else if (en) begin
            if (cnt >= MAX)
                cnt <= {W{1'b0}};  // 回卷
            else
                cnt <= cnt + 1'b1;
        end
    end
endmodule
