module addsub8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sub,
    output wire [7:0] y
);
    assign y = sub ? a - b : a + b;
endmodule

module hier_alu (
    input  wire       clk,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sub,
    output reg  [7:0] q
);
    wire [7:0] result;
    addsub8 u_addsub (.a(a), .b(b), .sub(sub), .y(result));
    always @(posedge clk)
        q <= result;
endmodule
