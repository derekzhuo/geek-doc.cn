// tb_adder_fixed.v —— 修复版测试台：去掉 `include，靠文件列表传入 adder.v
`timescale 1ns/1ps

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
