// Fixed-priority arbiter: requester 0 wins always.
module arb_fixed #(
    parameter N = 4
)(
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant
);
    integer i;
    reg found;
    always @(*) begin
        grant = {N{1'b0}};
        found = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (req[i] && !found) begin
                grant[i] = 1'b1;
                found = 1;
            end
        end
    end
endmodule
