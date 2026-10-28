// 顶层：故意用 4 位信号去接 8 位端口，触发 port width 警告
module top;
    reg  [3:0] a4;      // 只有 4 位，比端口窄
    reg  [7:0] b8;
    wire [7:0] sum;

    // a4 是 4 位，端口 a 是 8 位 -> 高位补零，iverilog 给出警告
    adder8 u_add (
        .a   (a4),
        .b   (b8),
        .sum (sum)
    );

    initial begin
        a4 = 4'hF;
        b8 = 8'h01;
        #1;
        $display("sum = %h (expected 10 if zero-extended)", sum);
        if (sum === 8'h10)
            $display("PASS: zero-extension worked");
        else
            $display("FAIL: sum mismatch");
        $finish;
    end
endmodule
