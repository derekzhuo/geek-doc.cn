// 错误 4：组合逻辑环（combinational loop）
// a 依赖 b，b 又依赖 a，没有寄存器打断 —— 电路上是不稳定振荡环
// 触发：synth 的 check 阶段报告；如实记录是告警还是报错
module comb_loop (
    input  wire sel,
    input  wire d,
    output wire y
);
    wire a;
    wire b;

    assign a = sel ? d : b;   // sel=0 时 a 依赖 b
    assign b = a;             // 而 b 直接等于 a → 环
    assign y = a;
endmodule
