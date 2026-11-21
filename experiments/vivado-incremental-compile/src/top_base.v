module top (
    input wire clk,
    input wire rst,
    input wire [31:0] d,
    output wire [31:0] q
);
wire [31:0] q0, q1, q2, q3;
leaf u0 (.clk(clk), .rst(rst), .d(d), .q(q0));
leaf u1 (.clk(clk), .rst(rst), .d(d + 32'h11111111), .q(q1));
leaf u2 (.clk(clk), .rst(rst), .d(d + 32'h22222222), .q(q2));
leaf u3 (.clk(clk), .rst(rst), .d(d + 32'h33333333), .q(q3));
assign q = q0 ^ q1 ^ q2 ^ q3;
endmodule
