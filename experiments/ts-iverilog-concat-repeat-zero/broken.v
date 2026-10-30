module optional_repeat #(
    parameter integer EXTRA = 0
) (
    input  wire [7:0] data,
    output wire [7:0] repeated
);
    // EXTRA=0 时，这里退化为非法的独立 {0{data}}。
    assign repeated = {EXTRA{data}};
endmodule

module broken_top;
    wire [7:0] repeated;
    optional_repeat #(.EXTRA(0)) dut (
        .data(8'hA5),
        .repeated(repeated)
    );
endmodule
