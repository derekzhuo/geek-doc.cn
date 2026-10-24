// MULTIDRIVEN: same reg driven from two always blocks
module multidriven_case (input wire clk, input wire a, input wire b, output reg q);
    always @(posedge clk) q <= a;
    always @(posedge clk) q <= b;
endmodule
