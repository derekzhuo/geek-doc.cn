// One mux stage: the external select bit prevents constant folding, while
// keep_hierarchy blocks cross-stage LUT merging so each instance keeps its
// own logic level in the synthesized netlist.
(* keep_hierarchy = "yes" *)
module mux_stage #(
  parameter integer WIDTH = 4
) (
  input  wire [WIDTH-1:0] a,
  input  wire             s,
  output wire [WIDTH-1:0] y
);

  assign y = s ? (a ^ (a >> 1)) : (a ^ {a[0], a[WIDTH-1:1]});

endmodule
