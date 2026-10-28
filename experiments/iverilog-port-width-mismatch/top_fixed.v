// 修复版：信号位宽与端口一致（8 位），警告消失
module top_fixed;
    reg  [7:0] a8;      // 与端口位宽对齐
    reg  [7:0] b8;
    wire [7:0] sum;

    adder8 u_add (
        .a   (a8),
        .b   (b8),
        .sum (sum)
    );

    initial begin
        a8 = 8'h0F;
        b8 = 8'h01;
        #1;
        $display("sum = %h (expected 10)", sum);
        if (sum === 8'h10)
            $display("PASS");
        else
            $display("FAIL: sum mismatch");
        $finish;
    end
endmodule
