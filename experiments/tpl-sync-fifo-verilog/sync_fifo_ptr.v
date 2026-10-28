// 同步 FIFO 模板（指针法）：深度 = 2**AW，指针多 1 bit 区分满与空
// 空：wptr == rptr；满：wptr 与 rptr 最高位相反、其余位相同
module sync_fifo_ptr #(
    parameter WIDTH = 8,
    parameter AW    = 4                // 深度 = 2**AW，必须是 2 的幂
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             full,
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             empty
);
    localparam DEPTH = (1 << AW);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0] wptr, rptr;             // 多 1 bit 折返位

    // 写放行条件：未满；或满但同拍有读（读腾出格子，写补上，保持满）
    wire wr_advance = wr_en & (~full | rd_en);
    wire rd_advance = rd_en & ~empty;

    assign empty = (wptr == rptr);
    assign full  = (wptr == {~rptr[AW], rptr[AW-1:0]});

    // 写侧：存储与写指针
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= {AW+1{1'b0}};
        end else begin
            if (wr_advance)
                mem[wptr[AW-1:0]] <= wr_data;
            wptr <= wptr + {{AW{1'b0}}, wr_advance};
        end
    end

    // 读侧：读指针（组合读出）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr <= {AW+1{1'b0}};
        end else begin
            rptr <= rptr + {{AW{1'b0}}, rd_advance};
        end
    end
    assign rd_data = mem[rptr[AW-1:0]];

endmodule
