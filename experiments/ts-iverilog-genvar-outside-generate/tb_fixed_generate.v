`timescale 1ns/1ps
module tb_fixed_generate;
    reg  [3:0] a;
    wire [3:0] y;
    integer k;

    fixed_generate dut (.a(a), .y(y));

    initial begin
        for (k = 0; k < 16; k = k + 1) begin
            a = k[3:0];
            #1;
            if (y !== ~a) begin
                $display("FAIL: a=%b y=%b", a, y);
                $finish(1);
            end
        end
        $display("fixed simulation PASS: all 16 input patterns");
        $finish(0);
    end
endmodule
