module hierarchical (
    input  logic clk,
    input  logic [31:0] seed,
    output logic [31:0] result
);
    logic [31:0] count0, count1, count2, count3;
    counter #(.OFFSET(0)) u0 (.clk(clk), .seed(seed), .count(count0));
    counter #(.OFFSET(1)) u1 (.clk(clk), .seed(seed), .count(count1));
    counter #(.OFFSET(2)) u2 (.clk(clk), .seed(seed), .count(count2));
    counter #(.OFFSET(3)) u3 (.clk(clk), .seed(seed), .count(count3));
    always_comb result = count0 ^ count1 ^ count2 ^ count3;
endmodule
