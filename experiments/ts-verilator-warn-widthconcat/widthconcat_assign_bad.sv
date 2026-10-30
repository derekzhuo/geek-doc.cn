module widthconcat_assign_bad (
  output logic [63:0] data
);
  always_comb begin
    data = {1, 2};
  end
endmodule
