module sized_bus #(
  parameter integer WIDTH = 8,
  parameter integer INDEX_WIDTH = (WIDTH <= 1) ? 1 : $clog2(WIDTH)
) (
  output wire [WIDTH-1:0] mask,
  output wire [INDEX_WIDTH-1:0] index
);
  assign mask = {WIDTH{1'b1}};
  assign index = {INDEX_WIDTH{1'b0}};
endmodule

module param_fixed (
  output wire [7:0] observed_mask,
  output wire [2:0] observed_index
);
  sized_bus #(.WIDTH(8)) u_dut (
    .mask(observed_mask),
    .index(observed_index)
  );
endmodule
