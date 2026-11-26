`timescale 1ns/1ps

module wave_tb;
    reg  [3:0] a;
    reg  [3:0] b;
    reg  [2:0] op;
    wire [3:0] result;
    wire n, z, c, v;
    reg [3:0] expected_result;
    reg expected_n, expected_z, expected_c, expected_v;
    integer fd;
    integer fields;
    integer vectors;
    integer failures;

    alu4 dut (.a(a), .b(b), .op(op), .result(result), .n(n), .z(z), .c(c), .v(v));

    initial begin
        $dumpfile("results/selected.vcd");
        $dumpvars(0, wave_tb);
        vectors = 0;
        failures = 0;
        fd = $fopen("wave_vectors.txt", "r");
        if (fd == 0)
            $fatal(1, "cannot open wave_vectors.txt");
        fields = $fscanf(fd, "%h %h %h %h %h %h %h %h\n",
                         op, a, b, expected_result,
                         expected_n, expected_z, expected_c, expected_v);
        while (fields == 8) begin
            #1;
            vectors = vectors + 1;
            $display("WAVE index=%0d op=%0h A=%0h B=%0h R=%0h NZCV=%0d%0d%0d%0d",
                     vectors - 1, op, a, b, result, n, z, c, v);
            if ({result, n, z, c, v} !==
                {expected_result, expected_n, expected_z, expected_c, expected_v})
                failures = failures + 1;
            fields = $fscanf(fd, "%h %h %h %h %h %h %h %h\n",
                             op, a, b, expected_result,
                             expected_n, expected_z, expected_c, expected_v);
        end
        $fclose(fd);
        if (vectors != 6 || failures != 0)
            $fatal(1, "selected waveform check failed: vectors=%0d failures=%0d", vectors, failures);
        $display("WAVE PASS vectors=6 failures=0");
        #1;
        $finish;
    end
endmodule
