// Multibit CDC experiment: direct 2-FF bus sync (wrong) vs Gray-code sync (right).
// Per-bit transport skew is modeled with different assign delays; a multi-bit
// increment then arrives at the destination flop bank at different times, so the
// direct path samples illegal intermediate values. The Gray path can only be off
// by one code step (old or new value), which maps back to a legal bus value.
`timescale 1ns/1ps
module tb_multibit_cdc;
    reg src_clk = 0;
    reg dst_clk = 0;
    reg rst_n = 0;
    wire [3:0] bus;

    src_counter u_src (.src_clk(src_clk), .rst_n(rst_n), .bus(bus));

    always #4 src_clk = ~src_clk;   // 125 MHz source
    always #5 dst_clk = ~dst_clk;   // 100 MHz destination

    // --- per-bit skew model (1ns / 2ns / 3ns / 4ns) ---
    wire [3:0] bus_skew;
    assign #1 bus_skew[0] = bus[0];
    assign #2 bus_skew[1] = bus[1];
    assign #3 bus_skew[2] = bus[2];
    assign #4 bus_skew[3] = bus[3];

    wire [3:0] gray_src  = (bus >> 1) ^ bus;
    wire [3:0] gray_skew;
    assign #1 gray_skew[0] = gray_src[0];
    assign #2 gray_skew[1] = gray_src[1];
    assign #3 gray_skew[2] = gray_src[2];
    assign #4 gray_skew[3] = gray_src[3];

    // --- GROUP DIRECT: plain 2-FF per bit (WRONG for multibit) ---
    reg [3:0] d_m1, d_m2;
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin d_m1 <= 0; d_m2 <= 0; end
        else begin d_m1 <= bus_skew; d_m2 <= d_m1; end
    end

    // --- GROUP GRAY: gray encode -> 2-FF -> decode (RIGHT) ---
    reg [3:0] g_m1, g_m2;
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin g_m1 <= 0; g_m2 <= 0; end
        else begin g_m1 <= gray_skew; g_m2 <= g_m1; end
    end
    wire [3:0] gray_dec;
    assign gray_dec[3] = g_m2[3];
    assign gray_dec[2] = g_m2[3] ^ g_m2[2];
    assign gray_dec[1] = gray_dec[2] ^ g_m2[1];
    assign gray_dec[0] = gray_dec[1] ^ g_m2[0];

    // legality tracking: keep last 4 values the source really held
    reg [3:0] hist [0:3];
    integer hw = 0;
    always @(posedge src_clk) begin
        #1;
        hist[hw] = bus;
        hw = (hw + 1) % 4;
    end

    function is_legal;
        input [3:0] v;
        integer k;
        begin
            is_legal = 0;
            for (k = 0; k < 4; k = k + 1)
                if (hist[k] === v) is_legal = 1;
        end
    endfunction

    integer illegal_direct = 0;
    integer illegal_gray = 0;
    integer samples = 0;

    always @(posedge dst_clk) begin
        #1;
        if (rst_n && $time > 100) begin
            samples = samples + 1;
            if (!is_legal(d_m2)) begin
                illegal_direct = illegal_direct + 1;
                $display("[%0t] DIRECT illegal intermediate sample: %0d (0x%h) -- never a real bus value",
                         $time, d_m2, d_m2);
            end
            if (!is_legal(gray_dec)) begin
                illegal_gray = illegal_gray + 1;
                $display("[%0t] GRAY illegal sample: %0d", $time, gray_dec);
            end
        end
    end

    initial begin
        $dumpfile("multibit_cdc.vcd");
        $dumpvars(0, tb_multibit_cdc);
        repeat (3) @(posedge src_clk);
        rst_n <= 1;
        repeat (120) @(posedge dst_clk);
        $display("samples=%0d illegal_direct=%0d illegal_gray=%0d",
                 samples, illegal_direct, illegal_gray);
        // expected physics: direct path shows glitches, gray path never does
        if (samples > 50 && illegal_direct > 0 && illegal_gray == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end
endmodule
