// WIDTH: assigning 8-bit value into 4-bit net truncates silently
module width_case (input wire [7:0] a, output wire [3:0] y);
    assign y = a;
endmodule
