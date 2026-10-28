// fixed_with_output.v: 补上输出端口，逻辑被保留
module top(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);
    reg [7:0] acc;
    always @(posedge clk) begin
        if (!rst_n)
            acc <= 8'd0;
        else
            acc <= acc + a + b;
    end
    assign sum = acc;
endmodule
