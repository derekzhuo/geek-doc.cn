// Behavioral equivalence check: for each state count, instantiate BIN / GRAY
// / OH encodings, feed identical stimulus, compare outputs cycle by cycle.
`timescale 1ns/1ps

module tb_fsm_walker;
    reg clk = 0;
    reg rst_n = 0;
    reg go = 0, back = 0;

    always #5 clk = ~clk;

    genvar gn;
    generate
        for (gn = 0; gn < 3; gn = gn + 1) begin : g_size
            localparam integer NS = (gn == 0) ? 4 : (gn == 1) ? 8 : 16;

            wire f_b, l_b, m_b, b_b;
            wire f_g, l_g, m_g, b_g;
            wire f_o, l_o, m_o, b_o;

            fsm_walker #(.NSTATES(NS), .ENC(0))  u_bin
                (clk, rst_n, go, back, f_b, l_b, m_b, b_b);
            fsm_walker #(.NSTATES(NS), .ENC(1)) u_gray
                (clk, rst_n, go, back, f_g, l_g, m_g, b_g);
            fsm_walker #(.NSTATES(NS), .ENC(2))   u_oh
                (clk, rst_n, go, back, f_o, l_o, m_o, b_o);

            integer cyc;
            always @(posedge clk) begin
                if (rst_n) begin
                    cyc = cyc + 1;
                    if ((f_b !== f_g) || (f_b !== f_o) ||
                        (l_b !== l_g) || (l_b !== l_o) ||
                        (m_b !== m_g) || (m_b !== m_o) ||
                        (b_b !== b_g) || (b_b !== b_o)) begin
                        $display("MISMATCH size=%0d cycle=%0d bin=%b%b%b%b gray=%b%b%b%b oh=%b%b%b%b",
                                 NS, cyc, f_b,l_b,m_b,b_b, f_g,l_g,m_g,b_g,
                                 f_o,l_o,m_o,b_o);
                        $fatal(1);
                    end
                end
            end

            initial begin
                // wait for the global stimulus sequence to finish, then report
                @(posedge rst_n);
                repeat (4*NS+12) @(posedge clk);
                $display("SIZE %0d: BIN/GRAY/OH outputs match on every cycle", NS);
            end
        end
    endgenerate

    // shared deterministic stimulus: walk forward to the end, try clamping,
    // walk back, try clamping at S0, then a random-ish go/back stream
    integer i;
    initial begin
        #2;
        @(posedge clk); rst_n = 1;
        // forward all the way (enough cycles for the 16-state variant)
        for (i = 0; i < 20; i = i+1) begin
            go = 1; back = 0; @(posedge clk);
        end
        // clamp at last
        go = 1; back = 0; @(posedge clk);
        // back all the way
        for (i = 0; i < 20; i = i+1) begin
            go = 0; back = 1; @(posedge clk);
        end
        // clamp at first
        go = 0; back = 1; @(posedge clk);
        // mixed stream (back wins over go when both high)
        for (i = 0; i < 16; i = i+1) begin
            go   = i[0];
            back = i[1];
            @(posedge clk);
        end
        go = 0; back = 0;
        repeat (4) @(posedge clk);
        $display("ALL EQUIVALENCE CHECKS PASSED");
        $finish;
    end
endmodule
