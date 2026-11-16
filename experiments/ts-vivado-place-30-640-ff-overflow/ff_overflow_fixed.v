// Same shift-register structure reduced to 2000 flip-flops, within xc7a35t capacity.
module ff_overflow_fixed (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output wire q
);
    (* SHREG_EXTRACT = "no", DONT_TOUCH = "true" *) reg [1999:0] chain;

    integer i;
    always @(posedge clk) begin
        if (rst)
            chain <= 2000'b0;
        else begin
            chain[0] <= d;
            for (i = 1; i < 2000; i = i + 1)
                chain[i] <= chain[i-1];
        end
    end

    assign q = chain[1999];
endmodule
