// 4 深度 8 位同步 FIFO（lint 修复版：显式补位 + 删掉无用信号）
module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output reg              full,
    output reg              empty
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [1:0] wptr;
    reg [1:0] rptr;
    reg [2:0] count;       // 0..4，3 位

    wire [3:0] status;

    assign status = {1'b0, count};   // 修复 1：显式零扩展，意图写在代码里

    always @(*) begin
        full  = (status == 4'd4);
        empty = (status == 4'd0);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr  <= 2'd0;
            rptr  <= 2'd0;
            count <= 3'd0;
            dout  <= 8'd0;
        end else begin
            if (wr_en && !full) begin
                mem[wptr] <= din;
                wptr <= wptr + 2'd1;
            end
            if (rd_en && !empty) begin
                dout <= mem[rptr];
                rptr <= rptr + 2'd1;
            end
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 3'd1; // 修复 3：写加、读减（仿真才能抓到的功能笔误）
                2'b01:   count <= count - 3'd1;
                default: count <= count;
            endcase
        end
    end
endmodule
