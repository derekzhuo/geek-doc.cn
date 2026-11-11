import sys
nblocks = int(sys.argv[1]); stages = int(sys.argv[2]); width = int(sys.argv[3])
open("rtl/bigblock.v","w").write(f"""module bigblock #(
  parameter int WIDTH = {width},
  parameter int STAGES = {stages}
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
""")
open("rtl/top.v","w").write(f"""module top #(
  parameter int NB = {nblocks}
)(
  input  logic             clk,
  input  logic [31:0]      d,
  output logic [31:0]      q
);
  logic [31:0] t [0:NB];
  assign t[0] = d;
  for (genvar b = 0; b < NB; b++) begin : g_blk
    bigblock #(.WIDTH({width}), .STAGES({stages})) u_bb (
      .clk(clk), .d(t[b]), .q(t[b+1])
    );
  end
  assign q = t[NB];
endmodule
""")
print(f"generated: NB={nblocks} STAGES={stages} WIDTH={width} FFs~{nblocks*stages*width}")
