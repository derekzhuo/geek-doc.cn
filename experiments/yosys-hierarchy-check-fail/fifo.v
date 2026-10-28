// fifo.v —— 参数化同步 FIFO 子模块（修复版需要把它一起 read_verilog）
module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output wire             full,
    output wire             empty
);

  localparam AW = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [AW:0] wr_ptr, rd_ptr;

  assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
  assign empty = (wr_ptr == rd_ptr);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr[AW-1:0]] <= din;
        wr_ptr <= wr_ptr + 1'b1;
      end
      if (rd_en && !empty) begin
        dout <= mem[rd_ptr[AW-1:0]];
        rd_ptr <= rd_ptr + 1'b1;
      end
    end
  end

endmodule
