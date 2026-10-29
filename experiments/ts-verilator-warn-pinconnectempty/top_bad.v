module top_bad (
    input  wire a,
    output wire y
);
  child u_child (
      .in(a),
      .out(y),
      .debug()
  );
endmodule
