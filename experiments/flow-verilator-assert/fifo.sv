// 4 项 8 位同步 FIFO：用 immediate assert 拦截空弹/满写
module fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 4,
  localparam int CW = $clog2(DEPTH+1)
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic                    wr_en,
  input  logic                    rd_en,
  input  logic [WIDTH-1:0]        din,
  output logic [WIDTH-1:0]        dout,
  output logic                    full,
  output logic                    empty,
  output logic [CW-1:0]            count
);
  logic [WIDTH-1:0]             mem [DEPTH];
  logic [$clog2(DEPTH)-1:0]     wptr, rptr;

  assign full  = (count == CW'(DEPTH));
  assign empty = (count == 0);
  assign dout  = mem[rptr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      count <= '0;
    end else begin
      // immediate assert：满时只写不读 = 溢出；空时只读不写 = 空弹
      a_no_overflow: assert (!(wr_en && full && !rd_en))
        else $error("FIFO overflow: write while full, count=%0d", count);
      a_no_underflow: assert (!(rd_en && empty && !wr_en))
        else $error("FIFO underflow: read while empty, count=%0d", count);

      if (wr_en && !(full && !rd_en)) begin
        mem[wptr] <= din;
        wptr      <= wptr + 1'b1;
      end
      if (rd_en && !(empty && !wr_en)) begin
        rptr <= rptr + 1'b1;
      end
      count <= count + CW'(wr_en && !(full && !rd_en))
                    - CW'(rd_en && !(empty && !wr_en));
    end
  end
endmodule
