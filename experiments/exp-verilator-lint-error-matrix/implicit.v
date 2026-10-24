// IMPLICIT: implicit wire declaration from typo'd identifier
module implicit_case (input wire a, input wire b, output wire y);
    assign y = a & bb;   // 'bb' is not declared; implicit 1-bit net
endmodule
