module child #(
  parameter integer WIDTH = 4,
  parameter integer OUT_WIDTH = WIDTH + 1
) (
  output wire [OUT_WIDTH-1:0] y
);
  assign y = {OUT_WIDTH{1'b1}};
endmodule

module top (
  output wire [4:0] default_y,
  output wire [8:0] override_y
);
  child u_default (
    .y(default_y)
  );

  child u_override (
    .y(override_y)
  );

  defparam u_override.WIDTH = 8;
endmodule
