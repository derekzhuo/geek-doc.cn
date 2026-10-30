module widthconcat_port_fixed (
  output logic [63:0] observed
);
  logic [63:0] pair;

  always_comb begin
    pair = {32'h1, 32'h2};
  end

  sink_64 u_sink (
    .data     (pair),
    .observed (observed)
  );
endmodule
