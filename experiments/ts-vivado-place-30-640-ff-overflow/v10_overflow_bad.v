// V10 bad case: 60000 explicit FFs on xc7a35t (41600 flip-flops max).
// SHREG_EXTRACT=no + DONT_TOUCH keep the chain from collapsing into SRL LUTs.
module v10_overflow_bad (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output wire q
);
    (* SHREG_EXTRACT = "no", DONT_TOUCH = "true" *) reg [59999:0] chain;

    integer i;
    always @(posedge clk) begin
        if (rst)
            chain <= 60000'b0;
        else begin
            chain[0] <= d;
            for (i = 1; i < 60000; i = i + 1)
                chain[i] <= chain[i-1];
        end
    end

    assign q = chain[59999];
endmodule
