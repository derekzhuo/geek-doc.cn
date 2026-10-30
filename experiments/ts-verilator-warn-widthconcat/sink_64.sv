module sink_64 (
  input  logic [63:0] data,
  output logic [63:0] observed
);
  always_comb begin
    observed = data;
  end
endmodule
