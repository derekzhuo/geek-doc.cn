// wide_lut_chain: 16 rounds of 64-bit rotate-xor-add mixing between two registers.
// Pure LUT/carry-chain combinational path, long enough to fail at 500 MHz and pass at 100 MHz.
module wide_lut_chain (
    input  wire        clk,
    input  wire [63:0] din,
    output reg  [63:0] dout
);
    reg [63:0] r_in;
    always @(posedge clk) r_in <= din;

    reg [63:0] c;
    integer i;
    always @* begin
        c = r_in;
        for (i = 0; i < 16; i = i + 1)
            c = (c ^ {c[62:0], c[63]}) + 64'h9E3779B97F4A7C15;
    end

    always @(posedge clk) dout <= c;
endmodule
