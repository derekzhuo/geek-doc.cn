// valid-ready handshake with random backpressure.
// Scoreboard compares input sequence to output sequence (no loss, no dup).
// Also reports backpressure cycle count and achieved throughput.
`timescale 1ns/1ps
module tb_valid_ready;
    parameter DW = 8;
    parameter N_ITEMS = 200;

    reg clk = 0, rst_n = 0;
    reg in_valid = 0;
    wire in_ready;
    reg [DW-1:0] in_data = 0;
    wire out_valid;
    reg out_ready = 0;
    wire [DW-1:0] out_data;

    vr_pipe #(.DW(DW)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready), .out_data(out_data)
    );

    always #5 clk = ~clk;

    integer sent = 0;
    integer recv = 0;
    integer errors = 0;
    integer bp_cycles = 0;    // cycles where out_valid && !out_ready (backpressured)
    integer stall_cycles = 0; // cycles where in_valid && !in_ready (upstream stalled)
    integer total_cycles = 0;

    reg [DW-1:0] model [0:4095];

    // sink: randomly drop out_ready (~40% low)
    always @(negedge clk) begin
        if (rst_n) out_ready <= ($random % 100 < 60);
        else       out_ready <= 0;
    end

    // source: keep in_valid high until all items accepted
    always @(posedge clk) begin
        #1;
        if (rst_n) begin
            total_cycles = total_cycles + 1;
            if (out_valid && !out_ready) bp_cycles = bp_cycles + 1;
            if (in_valid && !in_ready)   stall_cycles = stall_cycles + 1;
            if (in_valid && in_ready) begin
                model[sent] = in_data;
                sent = sent + 1;
            end
            if (out_valid && out_ready) begin
                if (out_data !== model[recv]) begin
                    errors = errors + 1;
                    $display("[%0t] MISMATCH got=%0d expect=%0d (recv=%0d)",
                             $time, out_data, model[recv], recv);
                end
                recv = recv + 1;
            end
        end
    end

    integer i;
    initial begin
        $dumpfile("valid_ready.vcd");
        $dumpvars(0, tb_valid_ready);
        repeat (3) @(posedge clk);
        rst_n <= 1;
        @(negedge clk);

        for (i = 0; i < N_ITEMS; i = i + 1) begin
            in_valid <= 1;
            in_data  <= i + 1;
            // hold until accepted
            begin : wait_accept
                integer guard;
                for (guard = 0; guard < 100; guard = guard + 1) begin
                    @(posedge clk); #1;
                    if (in_ready) begin
                        disable wait_accept;
                    end
                    @(negedge clk);
                end
            end
            @(negedge clk);
        end
        in_valid <= 0;

        // drain
        repeat (100) @(posedge clk);

        $display("sent=%0d recv=%0d errors=%0d", sent, recv, errors);
        $display("backpressure_cycles=%0d upstream_stall_cycles=%0d total_cycles=%0d",
                 bp_cycles, stall_cycles, total_cycles);
        $display("throughput = %0d items / %0d cycles", recv, total_cycles);
        if (errors == 0 && sent == N_ITEMS && recv == N_ITEMS && bp_cycles > 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end
endmodule
