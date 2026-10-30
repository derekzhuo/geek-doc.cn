module userwarn_bad #(
    parameter int DEPTH = 3
) ();
    if ((DEPTH & (DEPTH - 1)) != 0) begin : gen_depth_check
        $warning("DEPTH=%0d is not a power of two", DEPTH);
    end
endmodule
