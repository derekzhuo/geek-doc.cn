module \$not (A, Y);
    parameter A_WIDTH = 1;
    parameter Y_WIDTH = 1;
    parameter A_SIGNED = 0;
    input [A_WIDTH-1:0] A;
    output [Y_WIDTH-1:0] Y;

    // 错误：目标 $not 的模板又实例化同一个 $not。
    \$not #(
        .A_WIDTH(A_WIDTH), .Y_WIDTH(Y_WIDTH), .A_SIGNED(A_SIGNED)
    ) u_loop (.A(A), .Y(Y));
endmodule
