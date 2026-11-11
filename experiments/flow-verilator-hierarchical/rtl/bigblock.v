module bigblock #(
  parameter int WIDTH = 32,
  parameter int STAGES = 4096
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);
  logic [WIDTH-1:0] chain [0:STAGES];
  assign chain[0] = d;
  for (genvar i = 0; i < STAGES; i++) begin : g_chain
    always_ff @(posedge clk)
      chain[i+1] <= chain[i] ^ (i[WIDTH-1:0] + chain[i]);
  end
  assign q = chain[STAGES];
endmodule
