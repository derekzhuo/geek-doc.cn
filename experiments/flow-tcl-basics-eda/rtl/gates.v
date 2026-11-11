// 给 yosys tcl 控制流演示用的小模块之一
module gate_demo (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = (a & b) | (~a & b);
endmodule
