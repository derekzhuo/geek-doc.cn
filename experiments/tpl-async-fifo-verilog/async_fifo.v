// 异步 FIFO 模板：格雷码指针跨时钟同步（两级同步器）
// 参数化深度与位宽；满/空判定采用格雷码比较法
// DEPTH 必须为 2 的幂
module async_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,              // 必须是 2 的幂
    parameter AW    = $clog2(DEPTH)    // 地址位宽
)(
    // 写时钟域
    input  wire             wr_clk,
    input  wire             wr_rst_n,
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             full,    // 寄存量：写域时序输出
    // 读时钟域
    input  wire             rd_clk,
    input  wire             rd_rst_n,
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             empty    // 寄存量：读域时序输出
);

    // 双口存储体
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // 二进制指针（多 1 bit 用于区分满/空）
    reg [AW:0] wr_bin, rd_bin;
    // 格雷码指针
    reg [AW:0] wr_gray, rd_gray;
    // 跨时钟同步后的对端格雷码指针
    reg [AW:0] wr_gray_sync1, wr_gray_sync2;   // 写指针 -> 读域
    reg [AW:0] rd_gray_sync1, rd_gray_sync2;   // 读指针 -> 写域

    wire wr_advance = wr_en & ~full;
    wire rd_advance = rd_en & ~empty;
    wire [AW:0] wr_bin_next  = wr_bin + {{AW{1'b0}}, wr_advance};
    wire [AW:0] rd_bin_next  = rd_bin + {{AW{1'b0}}, rd_advance};
    wire [AW:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [AW:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    // 写侧：存储、指针更新
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= {AW+1{1'b0}};
            wr_gray <= {AW+1{1'b0}};
        end else begin
            if (wr_en && !full)
                mem[wr_bin[AW-1:0]] <= wr_data;
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // 读侧：指针更新
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= {AW+1{1'b0}};
            rd_gray <= {AW+1{1'b0}};
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

    assign rd_data = mem[rd_bin[AW-1:0]];

    // 写指针格雷码同步到读时钟域（两级寄存器）
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= {AW+1{1'b0}};
            wr_gray_sync2 <= {AW+1{1'b0}};
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    // 读指针格雷码同步到写时钟域（两级寄存器）
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= {AW+1{1'b0}};
            rd_gray_sync2 <= {AW+1{1'b0}};
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // 空判定：读指针格雷码追上同步过来的写指针格雷码（寄存量，读域输出）
    wire empty_val = (rd_gray_next == wr_gray_sync2);
    reg empty_r;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) empty_r <= 1'b1;
        else           empty_r <= empty_val;
    end
    assign empty = empty_r;

    // 满判定：写指针格雷码与同步过来的读指针格雷码高两位相反、其余位相同（寄存量，写域输出）
    wire full_val = (wr_gray_next == {~rd_gray_sync2[AW:AW-1], rd_gray_sync2[AW-2:0]});
    reg full_r;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) full_r <= 1'b0;
        else           full_r <= full_val;
    end
    assign full = full_r;

endmodule
