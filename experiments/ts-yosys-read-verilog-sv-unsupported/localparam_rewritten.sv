module top #(
    parameter integer WIDTH = 8
) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = data_in;
endmodule
