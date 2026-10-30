module top (
    input  logic clk,
    input  logic [31:0] seed,
    output logic [31:0] result
);
    logic [31:0] count0, count1, count2, count3;
    always_ff @(posedge clk) count0 <= count0 + seed;
    always_ff @(posedge clk) count1 <= count1 + seed + 1;
    always_ff @(posedge clk) count2 <= count2 + seed + 2;
    always_ff @(posedge clk) count3 <= count3 + seed + 3;
    always_comb result = count0 ^ count1 ^ count2 ^ count3;
endmodule
