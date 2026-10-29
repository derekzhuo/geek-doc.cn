module widthexpand_fixed (
    input  wire        [7:0]  unsigned_data,
    input  wire signed [7:0]  signed_data,
    output wire        [15:0] unsigned_result,
    output wire        [15:0] signed_result
);
    assign unsigned_result = {8'h00, unsigned_data};
    assign signed_result   = {{8{signed_data[7]}}, signed_data};
endmodule
