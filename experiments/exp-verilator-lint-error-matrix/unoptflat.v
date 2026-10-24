// UNOPTFLAT: combinational loop between two nets
module unopt_case (input wire a, output wire y);
    wire x, z;
    assign x = z | a;
    assign z = x;
    assign y = x;
endmodule
