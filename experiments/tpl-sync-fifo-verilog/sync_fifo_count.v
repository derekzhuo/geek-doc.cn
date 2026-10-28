// 同步 FIFO 模板（计数器法）：DEPTH 可为任意正整数
// 空满由计数器 cnt 直接给出：cnt==0 为空，cnt==DEPTH 为满
// 满时若同拍有读，写被放行（读腾出位置，写补上），FIFO 保持满
module sync_fifo_count #(
    parameter WIDTH = 8,
    parameter DEPTH = 16               // 任意正整数，不要求 2 的幂
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             full,
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             empty,
    output wire [$clog2(DEPTH):0] count
);
    localparam CW = $clog2(DEPTH);        // 地址位宽
    localparam [31:0] LAST32 = DEPTH - 1; // 末地址（32 位常量，比较时切片）

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [CW-1:0] wptr, rptr;              // 地址指针，到达末地址手动回绕
    reg [CW:0]   cnt;                     // 占用计数器，0..DEPTH

    // 写放行条件：未满；或满但同拍有读（读腾出格子）
    wire wr_advance = wr_en & (~full | rd_en);
    wire rd_advance = rd_en & ~empty;

    assign full  = (cnt == DEPTH[CW:0]);
    assign empty = (cnt == 0);
    assign count = cnt;

    // 写侧：存储与写指针
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= {CW{1'b0}};
        end else if (wr_advance) begin
            mem[wptr] <= wr_data;
            wptr <= (wptr == LAST32[CW-1:0]) ? {CW{1'b0}} : wptr + 1'b1;
        end
    end

    // 读侧：读指针（组合读出）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr <= {CW{1'b0}};
        end else if (rd_advance) begin
            rptr <= (rptr == LAST32[CW-1:0]) ? {CW{1'b0}} : rptr + 1'b1;
        end
    end
    assign rd_data = mem[rptr];

    // 计数器：同时读写时不变
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else begin
            case ({wr_advance, rd_advance})
                2'b10:   cnt <= cnt + 1'b1;
                2'b01:   cnt <= cnt - 1'b1;
                default: cnt <= cnt;      // 00 无操作；11 一进一出抵消
            endcase
        end
    end

endmodule
