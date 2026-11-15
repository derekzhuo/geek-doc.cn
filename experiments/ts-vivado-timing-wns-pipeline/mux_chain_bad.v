// 64 mux stages in one combinational cloud between two flip-flops.
(* DONT_TOUCH = "yes" *)
module mux_chain_bad #(
  parameter integer LEVELS = 64,
  parameter integer WIDTH  = 4
) (
  input  wire              clk,
  input  wire [WIDTH-1:0]  din,
  input  wire [LEVELS-1:0] sel,
  output reg  [WIDTH-1:0]  dout
);

  reg  [WIDTH-1:0] cap;
  wire [WIDTH-1:0] cloud [0:LEVELS];

  assign cloud[0] = cap;

  genvar i;
  generate
    for (i = 0; i < LEVELS; i = i + 1) begin: g_chain
      mux_stage #(.WIDTH(WIDTH)) u_stage (
        .a(cloud[i]),
        .s(sel[i]),
        .y(cloud[i+1])
      );
    end
  endgenerate

  always @(posedge clk) begin
    cap  <= din;
    dout <= cloud[LEVELS];
  end

endmodule
