module usererror_bad #(
    parameter int WIDTH = 0
) ();
    if (WIDTH <= 0) begin : gen_width_check
        $error("WIDTH must be positive, got %0d", WIDTH);
    end
endmodule
