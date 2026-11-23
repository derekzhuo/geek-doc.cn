`timescale 1ns/1ps
// "1101" sequence detector with overlapping matches.
// State encodes the longest suffix of the received stream that is also a
// prefix of the target pattern 1101:
//   S0 = no prefix, S1 = "1", S2 = "11", S3 = "110"
// Next state is combinational (Mealy transition logic); `found` is
// registered on the same clock so the output is a clean one-cycle pulse
// with no combinational glitches.
module seq_detector_mealy (
  input  wire clk,
  input  wire rst_n,
  input  wire din,
  output reg  found
);
  localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;

  reg [1:0] state;
  reg [1:0] next_state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= S0;
    else
      state <= next_state;
  end

  always @(*) begin
    next_state = state;
    case (state)
      S0: next_state = din ? S1 : S0;
      S1: next_state = din ? S2 : S0;
      S2: next_state = din ? S2 : S3;
      S3: begin
        if (din)
          // Pattern complete; the trailing '1' is also the prefix "1"
          // of a potential next match, which enables overlapping hits.
          next_state = S1;
        else
          next_state = S0;
      end
      default: next_state = S0;
    endcase
  end

  // Registered Mealy output: high for one full clock after the cycle in
  // which state S3 sees a matching '1'.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      found <= 1'b0;
    else
      found <= (state == S3) && din;
  end
endmodule