module params_fixed #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 4
) ();
    if (WIDTH <= 0) begin : gen_width_check
        $error("WIDTH must be positive, got %0d", WIDTH);
    end
    if (DEPTH < 2) begin : gen_depth_check
        $error("DEPTH must be at least 2, got %0d", DEPTH);
    end else if ((DEPTH & (DEPTH - 1)) != 0) begin : gen_depth_advisory
        $warning("DEPTH=%0d is not a power of two", DEPTH);
    end
endmodule
