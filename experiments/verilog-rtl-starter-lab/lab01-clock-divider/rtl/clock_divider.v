// Parameterized clock divider: `out` toggles once every DIV input clocks,
// so f_out = f_clk / (2 * DIV). Active-low asynchronous reset.
module clock_divider #(
  parameter DIV = 4
) (
  input  wire clk,
  input  wire rst_n,
  output reg  out
);
  localparam CW = $clog2(DIV);

  reg [CW-1:0] cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= {CW{1'b0}};
      out <= 1'b0;
    end else if (cnt == DIV - 1) begin
      cnt <= {CW{1'b0}};
      out <= ~out;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end
endmodule
