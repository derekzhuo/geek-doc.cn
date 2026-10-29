module top (
    input  wire a,
    input  wire b,
    output wire y
);
    pulse u_pulse (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule
