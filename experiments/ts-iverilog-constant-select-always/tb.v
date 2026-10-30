`timescale 1ns/1ps
module tb;
    reg a;
    wire y;

    fixed dut (
        .a(a),
        .y(y)
    );

    initial begin
        a = 1'b0;
        #1;
        if (y !== 1'b0) begin
            $display("FAIL: a=0, y=%b", y);
            $finish(1);
        end
        a = 1'b1;
        #1;
        if (y !== 1'b1) begin
            $display("FAIL: a=1, y=%b", y);
            $finish(1);
        end
        $display("PASS: constant part-select and bit-select are valid reg l-values");
        $finish;
    end
endmodule
