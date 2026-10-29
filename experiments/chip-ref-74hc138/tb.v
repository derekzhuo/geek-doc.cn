`timescale 1ns/1ps
module tb;
    reg g1, g2a_n, g2b_n;
    reg [2:0] a;
    wire [7:0] y_n;
    integer vector;
    integer errors;
    reg [7:0] expected;

    decoder_74hc138 dut(.g1(g1), .g2a_n(g2a_n), .g2b_n(g2b_n), .a(a), .y_n(y_n));

    initial begin
        errors = 0;
        for (vector = 0; vector < 64; vector = vector + 1) begin
            {g1, g2a_n, g2b_n, a} = vector[5:0];
            #1;
            if (g1 && !g2a_n && !g2b_n)
                expected = ~(8'b0000_0001 << a);
            else
                expected = 8'hff;
            if (y_n !== expected) begin
                errors = errors + 1;
                $display("FAIL vector=%0d g1=%b g2a_n=%b g2b_n=%b a=%0d y_n=%02h expected=%02h", vector, g1, g2a_n, g2b_n, a, y_n, expected);
            end
        end
        $display("SUMMARY vectors=64 errors=%0d", errors);
        if (errors == 0)
            $display("PASS all address and enable combinations");
        else
            $display("FAIL mismatch detected");
        $finish;
    end
endmodule
