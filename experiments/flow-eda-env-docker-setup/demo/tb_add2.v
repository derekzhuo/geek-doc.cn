`timescale 1ns/1ps
module tb_add2;
    reg  [1:0] a, b;
    wire [2:0] s;

    add2 dut (.a(a), .b(b), .s(s));

    initial begin
        a = 2'd1; b = 2'd2;
        #10 $display("sum=%0d (expect 3)", s);
        #10 $finish;
    end
endmodule
