// 16x8 synchronous FIFO with count-based full/empty flags
module fifo #(
    parameter W  = 8,
    parameter AW = 4
) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          wr_en,
    input  wire          rd_en,
    input  wire [W-1:0]  din,
    output reg  [W-1:0]  dout,
    output wire          full,
    output wire          empty
);
    reg [W-1:0]  mem [0:(1 << AW) - 1];
    reg [AW:0]   cnt;
    reg [AW-1:0] wp;
    reg [AW-1:0] rp;

    assign full  = (cnt == (1 << (AW + 1)) - 1);
    assign empty = (cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wp   <= {AW{1'b0}};
            rp   <= {AW{1'b0}};
            cnt  <= {(AW+1){1'b0}};
            dout <= {W{1'b0}};
        end else begin
            case ({wr_en, rd_en})
                2'b10: if (!full) begin
                    mem[wp] <= din;
                    wp  <= wp + 1'b1;
                    cnt <= cnt + 1'b1;
                end
                2'b01: if (!empty) begin
                    dout <= mem[rp];
                    rp   <= rp + 1'b1;
                    cnt  <= cnt - 1'b1;
                end
                2'b11: begin
                    mem[wp] <= din;
                    wp  <= wp + 1'b1;
                    rp  <= rp + 1'b1;
                    dout <= mem[rp];
                end
                default: ;
            endcase
        end
    end
endmodule
