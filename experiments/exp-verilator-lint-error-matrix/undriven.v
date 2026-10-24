// UNDRIVEN: net consumed but never driven
module undriven_case (input wire a, output wire y);
    wire ghost;
    assign y = a & ghost;
endmodule
