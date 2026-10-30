module leaf(
    input  wire a,
    output wire y
);
    assign y = ~a;
endmodule

module named_top(
    input  wire a,
    output wire y
);
    generate
        if (1) begin : decode_scope
            wire local_a;
            assign local_a = a;
            leaf u_leaf (
                .a(local_a),
                .y(y)
            );
        end
    endgenerate
endmodule
