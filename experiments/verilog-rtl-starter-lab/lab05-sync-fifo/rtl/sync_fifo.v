// Single-clock synchronous FIFO.
// Depth should be a power of two so pointer wrap comes for free.
// Full/empty are derived from a running occupancy counter, which makes
// the boundary conditions explicit: writes while full and reads while
// empty are ignored. Read data is combinational from the read pointer.
module sync_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire             wr_en,
  input  wire             rd_en,
  input  wire [WIDTH-1:0] wr_data,
  output wire [WIDTH-1:0] rd_data,
  output wire             full,
  output wire             empty,
  output reg  [$clog2(DEPTH):0] count
);
  localparam AW = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [AW-1:0] wr_ptr;
  reg [AW-1:0] rd_ptr;

  wire do_wr = wr_en && !full;
  wire do_rd = rd_en && !empty;

  integer k;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= {AW{1'b0}};
      rd_ptr <= {AW{1'b0}};
      count  <= {($clog2(DEPTH) + 1){1'b0}};
      for (k = 0; k < DEPTH; k = k + 1)
        mem[k] <= {WIDTH{1'b0}};
    end else begin
      if (do_wr) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= wr_ptr + 1'b1;
      end
      if (do_rd) begin
        rd_ptr <= rd_ptr + 1'b1;
      end

      // Occupancy: simultaneous read+write leaves count unchanged.
      case ({do_wr, do_rd})
        2'b10:   count <= count + 1'b1;
        2'b01:   count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

  assign rd_data = mem[rd_ptr];
  assign full    = (count == DEPTH);
  assign empty   = (count == 0);
endmodule
