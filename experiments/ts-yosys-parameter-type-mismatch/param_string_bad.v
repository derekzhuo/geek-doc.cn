module sized_bus #(
  parameter integer WIDTH = 8
) (
  output wire [WIDTH-1:0] mask
);
  assign mask = {WIDTH{1'b1}};
endmodule

module param_string_bad (
  output wire [55:0] observed
);
  sized_bus #(.WIDTH("8")) u_dut (
    .mask(observed)
  );
endmodule
