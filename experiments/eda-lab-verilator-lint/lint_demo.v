// lint_demo.v —— 故意埋了 6 类典型问题的问题 RTL，供 verilator --lint-only 收集真实告警
// 问题清单：
//   1. WIDTH          位宽不匹配（8 位表达式赋给 16 位、32 位常量截断到 4 位）
//   2. UNOPTFLAT      组合逻辑成环（a 依赖 b、b 依赖 a）
//   3. LATCH          不完整的 if 推断出锁存器
//   4. UNUSED         声明了但没人用的信号
//   5. CASEINCOMPLETE case 分支不全且无 default
//   6. UNDRIVEN       信号从未被驱动

module lint_demo (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  din,
    input  wire [1:0]  sel,
    input  wire        unused_port,   // 顶层端口：属于对外接口，lint 不会报它未用
    output reg  [15:0] dout,
    output wire        loop_out       // 把组合环引出来，防止被当死代码优化掉
);

    // ---- 1. WIDTH：8 位 + 8 位 = 8 位，赋给 16 位；常量 32'd7 截断到 4 位 ----
    reg  [7:0]  a8;
    reg  [3:0]  nibble;

    always @(posedge clk) begin
        if (!rst_n) begin
            a8     <= 8'd0;
            nibble <= 4'd0;
        end else begin
            a8     <= din + 8'd1;
            nibble <= 32'd7;              // WIDTH：32 位常量赋给 4 位寄存器
        end
    end

    always @(*) begin
        dout = a8 + din;                  // WIDTH：加法结果 8 位，扩展赋 16 位
    end

    // ---- 2. UNOPTFLAT：组合环，x 依赖 y、y 依赖 x ----
    wire loop_x;
    wire loop_y;
    assign loop_x = loop_y & din[0];
    assign loop_y = loop_x | din[1];
    assign loop_out = loop_x;

    // ---- 3. LATCH：if 没有 else，en 为低时 q_latch 保持，推断锁存器 ----
    reg q_latch;
    always @(*) begin
        if (din[2]) begin
            q_latch = din[3];
        end
    end

    // ---- 4. UNUSED / 6. UNDRIVEN：声明了没人用、也从未被驱动 ----
    wire [3:0] never_used;
    wire       never_driven;

    // ---- 5. CASEINCOMPLETE：4 选 1 的 case 漏了 2'b11，也没 default ----
    reg [7:0] mux_out;
    always @(*) begin
        case (sel)
            2'b00:   mux_out = din;
            2'b01:   mux_out = ~din;
            2'b10:   mux_out = 8'hAA;
        endcase
    end

endmodule
