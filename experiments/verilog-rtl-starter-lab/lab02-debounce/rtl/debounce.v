// Switch/button debouncer for a synchronous design.
// Two-stage synchronizer first, then a stability counter: the input must
// stay different from the latched level for N consecutive clocks before
// the level changes. db_pulse fires for one clock on a stable press.
module debounce #(
  parameter N = 4
) (
  input  wire clk,
  input  wire rst_n,
  input  wire noisy,
  output reg  db_level,
  output wire db_pulse
);
  localparam CW = $clog2(N + 1);

  reg sync1, sync2;
  reg [CW-1:0] cnt;

  // Two-stage synchronizer: reduces metastability risk from asynchronous input.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
    end else begin
      sync1 <= noisy;
      sync2 <= sync1;
    end
  end

  // Stability window: accept the new level only after N matching samples.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt      <= {CW{1'b0}};
      db_level <= 1'b0;
    end else if (sync2 != db_level) begin
      if (cnt == N - 1) begin
        cnt      <= {CW{1'b0}};
        db_level <= sync2;
      end else begin
        cnt <= cnt + 1'b1;
      end
    end else begin
      cnt <= {CW{1'b0}};
    end
  end

  // One-cycle pulse when a press (0 -> 1) passes the stability window.
  assign db_pulse = (cnt == N - 1) && (sync2 == 1'b1) && (db_level == 1'b0);
endmodule
