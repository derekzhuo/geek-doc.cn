module widthconcat_port_bad (
  output logic [63:0] observed
);
  sink_64 u_sink (
    .data     ({1, 2}),
    .observed (observed)
  );
endmodule
