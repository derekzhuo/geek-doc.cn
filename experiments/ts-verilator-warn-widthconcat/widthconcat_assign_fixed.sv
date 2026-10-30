module widthconcat_assign_fixed (
  output logic [63:0] data
);
  always_comb begin
    data = {32'h1, 32'h2};
  end
endmodule
