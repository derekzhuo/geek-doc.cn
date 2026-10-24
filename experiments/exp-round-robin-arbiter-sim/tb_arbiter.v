// Same random heavy-load request stimulus into fixed-priority and round-robin
// arbiters. PASS = fixed starves low-priority requesters while round-robin
// stays near-uniform.
`timescale 1ns/1ps
module tb_arbiter;
    parameter N = 4;
    parameter CYCLES = 500;

    reg clk = 0, rst_n = 0;
    reg [N-1:0] req = 0;
    wire [N-1:0] grant_fixed, grant_rr;

    arb_fixed #(.N(N)) u_fixed (.req(req), .grant(grant_fixed));
    arb_rr    #(.N(N)) u_rr (.clk(clk), .rst_n(rst_n), .req(req), .grant(grant_rr));

    always #5 clk = ~clk;

    integer cnt_fixed [0:N-1];
    integer cnt_rr    [0:N-1];
    integer i, cyc;
    integer min_rr, max_rr;
    integer starved_fixed;

    initial begin
        for (i = 0; i < N; i = i + 1) begin
            cnt_fixed[i] = 0; cnt_rr[i] = 0;
        end
        repeat (3) @(posedge clk);
        rst_n <= 1;
        @(negedge clk);

        // heavy load: each requester asks with ~85% duty -> constant contention
        for (cyc = 0; cyc < CYCLES; cyc = cyc + 1) begin
            for (i = 0; i < N; i = i + 1)
                req[i] <= ($random % 100 < 85);
            @(posedge clk); #1;
            for (i = 0; i < N; i = i + 1) begin
                if (grant_fixed[i]) cnt_fixed[i] = cnt_fixed[i] + 1;
                if (grant_rr[i])    cnt_rr[i]    = cnt_rr[i] + 1;
            end
            @(negedge clk);
        end
        req <= 0;

        $display("grant distribution over %0d cycles:", CYCLES);
        for (i = 0; i < N; i = i + 1)
            $display("  requester %0d: fixed=%0d rr=%0d", i, cnt_fixed[i], cnt_rr[i]);

        // fixed: requester 3 (lowest priority) should be (near) starved
        starved_fixed = (cnt_fixed[N-1] < CYCLES / 20);
        // rr: max/min spread should be small
        min_rr = cnt_rr[0]; max_rr = cnt_rr[0];
        for (i = 1; i < N; i = i + 1) begin
            if (cnt_rr[i] < min_rr) min_rr = cnt_rr[i];
            if (cnt_rr[i] > max_rr) max_rr = cnt_rr[i];
        end
        $display("rr spread max-min=%0d (threshold %0d), fixed_lowest=%0d",
                 max_rr - min_rr, CYCLES / 10, cnt_fixed[N-1]);

        if (starved_fixed && (max_rr - min_rr) <= CYCLES / 10 && min_rr > 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end
endmodule
