// 教学用同步 FIFO：深度 4、位宽 8，内部读写握手线引出便于观测
module sync_fifo #(parameter W=8, D=4, AW=2) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          wr_en,
    input  wire          rd_en,
    input  wire [W-1:0]  din,
    output reg  [W-1:0]  dout,
    output wire          full,
    output wire          empty,
    output reg  [AW:0]   cnt,
    output wire          fire_wr,   // 实际写握手
    output wire          fire_rd    // 实际读握手
);
    reg [W-1:0] mem [0:D-1];
    reg [AW-1:0] wp, rp;

    assign fire_wr = wr_en & ~full;
    assign fire_rd = rd_en & ~empty;

    always @(posedge clk) begin
        if (!rst_n) begin
            wp <= 0; rp <= 0; cnt <= 0;
            dout <= 0;
        end else begin
            if (fire_wr) begin mem[wp] <= din; wp <= wp + 1'b1; end
            if (fire_rd) begin dout <= mem[rp]; rp <= rp + 1'b1; end
            case ({fire_wr, fire_rd})
                2'b10: cnt <= cnt + 1'b1;
                2'b01: cnt <= cnt - 1'b1;
                default: cnt <= cnt;
            endcase
        end
    end

    // full/empty 只由寄存器 cnt 译码，避免 full 与 fire_wr 之间形成组合环
    assign full  = (cnt == D);
    assign empty = (cnt == 0);
endmodule
