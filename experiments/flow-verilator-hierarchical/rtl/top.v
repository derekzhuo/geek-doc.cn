module top #(
  parameter int NB = 16
)(
  input  logic             clk,
  input  logic [31:0]      d,
  output logic [31:0]      q
);
  logic [31:0] t [0:NB];
  assign t[0] = d;
  for (genvar b = 0; b < NB; b++) begin : g_blk
    bigblock #(.WIDTH(32), .STAGES(4096)) u_bb (
      .clk(clk), .d(t[b]), .q(t[b+1])
    );
  end
  assign q = t[NB];
endmodule
