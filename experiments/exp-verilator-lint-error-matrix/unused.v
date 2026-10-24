// UNUSED: driven signal never consumed
module unused_case (input wire clk, input wire [7:0] d, output wire y);
    reg [7:0] r;
    always @(posedge clk) r <= d;
    assign y = r[0];
endmodule
