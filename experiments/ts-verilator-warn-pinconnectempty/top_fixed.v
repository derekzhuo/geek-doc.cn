module top_fixed (
    input  wire a,
    output wire y
);
  wire unused_debug;

  child u_child (
      .in(a),
      .out(y),
      .debug(unused_debug)
  );
endmodule
