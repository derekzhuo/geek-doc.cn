module widthexpand_broken (
    input  wire        [7:0]  unsigned_data,
    input  wire signed [7:0]  signed_data,
    output wire        [15:0] unsigned_result,
    output wire        [15:0] signed_result
);
    assign unsigned_result = unsigned_data;
    assign signed_result   = signed_data;
endmodule
