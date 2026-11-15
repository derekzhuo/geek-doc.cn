// The same 64 mux stages, split into 32 groups of two with a pipeline
// register between groups. Each flip-flop-to-flip-flop path now spans two
// logic levels; latency increases in exchange for the timing closure.
(* DONT_TOUCH = "yes" *)
module mux_chain_pipelined #(
  parameter integer LEVELS = 64,
  parameter integer PIPE   = 2,
  parameter integer WIDTH  = 4
) (
  input  wire              clk,
  input  wire [WIDTH-1:0]  din,
  input  wire [LEVELS-1:0] sel,
  output reg  [WIDTH-1:0]  dout
);

  localparam integer GROUPS = LEVELS / PIPE;

  reg [WIDTH-1:0] pipe_reg [0:GROUPS-1];

  genvar g;
  genvar k;
  generate
    for (g = 0; g < GROUPS; g = g + 1) begin: g_group
      wire [WIDTH-1:0] inner [0:PIPE];
      assign inner[0] = (g == 0) ? din : pipe_reg[g-1];
      for (k = 0; k < PIPE; k = k + 1) begin: g_lut
        mux_stage #(.WIDTH(WIDTH)) u_stage (
          .a(inner[k]),
          .s(sel[g*PIPE + k]),
          .y(inner[k+1])
        );
      end
      always @(posedge clk) begin
        pipe_reg[g] <= inner[PIPE];
      end
    end
  endgenerate

  always @(posedge clk) begin
    dout <= pipe_reg[GROUPS-1];
  end

endmodule
