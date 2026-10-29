module top (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] y
);
    vendor_adder #(.WIDTH(4)) u_adder (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule
