// Syntax error trigger: the continuous assignment is missing its terminating
// semicolon. The parser cannot recover at the next 'assign' keyword and
// reports the token position where parsing broke.
module syntax_bad (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y,
    output wire z
);
    assign y = a & b
    assign z = y | c;
endmodule
