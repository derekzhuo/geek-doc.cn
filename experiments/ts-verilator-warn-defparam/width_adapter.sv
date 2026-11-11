module width_adapter #(
  parameter integer WIDTH = 8
) (
  input  logic [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out
);
  assign data_out = data_in;
endmodule
