// Demo design for yosys TCL-style scripting steps.
module sub_add (input wire [7:0] a, input wire [7:0] b, output wire [8:0] y);
    assign y = a + b;
endmodule

module top_demo (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       sel,
    output wire [8:0] y
);
    wire [8:0] sum;
    sub_add u_add (.a(a), .b(b), .y(sum));
    assign y = sel ? sum : {1'b0, a};
endmodule
