package count_pkg;
    parameter int WIDTH = 8;
endpackage

module top
    import count_pkg::*;
(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = data_in;
endmodule
