module widthtrunc_fixed (
    input  wire [15:0] wide_data,
    output wire [7:0]  narrow_data,
    output wire [7:0]  high_data
);
    assign high_data   = wide_data[15:8];
    assign narrow_data = wide_data[7:0];
endmodule
