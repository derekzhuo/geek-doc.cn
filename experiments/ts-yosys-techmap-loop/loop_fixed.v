module \$not (A, Y);
    parameter A_WIDTH = 1;
    parameter Y_WIDTH = 1;
    parameter A_SIGNED = 0;
    input [A_WIDTH-1:0] A;
    output [Y_WIDTH-1:0] Y;

    // 修复：显式落到门级 $_NOT_，不再产生 $not。
    \$_NOT_ u_fixed (.A(A), .Y(Y));
endmodule
