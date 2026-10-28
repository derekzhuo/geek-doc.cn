// tb_adder.v —— adder 的测试台
`timescale 1ns/1ps
`include "adder.v"

module tb_adder;
    reg  [7:0] a, b;
    wire [8:0] sum;

    adder u_adder (.a(a), .b(b), .sum(sum));

    initial begin
        a = 8'd25; b = 8'd17;
        #10;
        if (sum !== 9'd42) begin
            $display("FAIL: sum=%0d expected 42", sum);
            $finish(1);
        end
        $display("PASS: 25 + 17 = %0d", sum);
        $finish;
    end
endmodule
