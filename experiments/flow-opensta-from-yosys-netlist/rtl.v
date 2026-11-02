// RTL source: a two-stage pipeline with a two-level NAND gating submodule.
// Intentionally hierarchical to show the flatten handoff to OpenSTA.
module gating (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y
);
    wire t;
    assign t = ~(a & b);
    assign y = ~(t & c);
endmodule

module top (
    input  wire clk,
    input  wire d,
    input  wire en,
    input  wire en2,
    output reg  q
);
    reg  s1;
    wire n1;

    gating u_g (.a(s1), .b(en), .c(en2), .y(n1));

    always @(posedge clk)
        s1 <= d;

    always @(posedge clk)
        q  <= n1;
endmodule
