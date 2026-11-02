// Intentionally incomplete sensitivity / missing else: a latch gets inferred.
// Used only to show what latch-based storage looks like in `stat`.
module latch_demo (
    input  wire en,
    input  wire d,
    output reg  q
);
    always @(*) begin
        if (en)
            q = d;
    end
endmodule
