module adder (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
  assign {cout, sum} = {1'b0, a} + {1'b0, b} + {8'd0, cin};
endmodule
