module defparam_fixed (
  input  logic [3:0] data_in,
  output logic [3:0] data_out
);
  width_adapter #(
    .WIDTH (4)
  ) u_adapter (
    .data_in  (data_in),
    .data_out (data_out)
  );
endmodule
