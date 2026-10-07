// 错误4：模块名拼错——实例化的模块名不存在
module sub_real (
    input  wire a,
    output wire b
);
    assign b = ~a;
endmodule

module top (
    input  wire din,
    output wire dout
);
    // 真实模块叫 sub_real，这里拼成了 sub_raal
    sub_raal u0 (
        .a (din),
        .b (dout)
    );
endmodule
