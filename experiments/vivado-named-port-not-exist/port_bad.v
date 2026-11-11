// BAD: the instantiation maps a formal port named c that does not exist on and_sub.
// Vivado synthesis emits [Synth 8-4480] formal port ... does not exist.
module port_bad (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y
);
    and_sub u_and (
        .a (a),
        .b (b),
        .c (c),
        .y (y)
    );
endmodule
