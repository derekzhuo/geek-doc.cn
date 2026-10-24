// Round-robin arbiter: combinational grant from a rotating priority base.
module arb_rr #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant
);
    reg [N-1:0] base;   // one-hot: position with highest priority this cycle

    integer base_idx;
    integer i;
    reg found;
    always @(*) begin
        base_idx = 0;
        for (i = 0; i < N; i = i + 1)
            if (base[i]) base_idx = i;
    end

    always @(*) begin
        grant = {N{1'b0}};
        found = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (req[(base_idx + i) % N] && !found) begin
                grant[(base_idx + i) % N] = 1'b1;
                found = 1;
            end
        end
    end

    // rotate base to one past the granted position
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base <= {{(N-1){1'b0}}, 1'b1};
        end else if (grant != 0) begin
            for (j = 0; j < N; j = j + 1)
                if (grant[j])
                    base <= {{(N-1){1'b0}}, 1'b1} << ((j + 1) % N);
        end
    end
endmodule
