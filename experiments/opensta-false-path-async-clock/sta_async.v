// sta_async.v — two asynchronous clock domains with a 2-flop synchronizer crossing
module sta_async (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire [7:0] din_a,
    output wire [7:0] dout_b
);
    reg [7:0] reg_a;
    reg [7:0] sync1;
    reg [7:0] reg_b;

    always @(posedge clk_a)
        reg_a <= din_a;

    always @(posedge clk_b) begin
        sync1 <= reg_a;
        reg_b <= sync1;
    end

    assign dout_b = reg_b;
endmodule
