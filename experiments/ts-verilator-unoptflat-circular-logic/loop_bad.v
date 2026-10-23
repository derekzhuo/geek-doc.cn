// 组合逻辑成环的最小复现：x 与 z 通过两条互斥 assign 互相依赖
// verilator --lint-only -Wall loop_bad.v
// 预期：%Warning-UNOPTFLAT: Signal unoptimizable: Feedback to clock or circular logic
module loop_bad (
    input  wire sel,
    input  wire a,
    input  wire b,
    output wire y
);
    wire x, z;
    assign x = sel ? a : z;
    assign z = sel ? b : x;
    assign y = x & z;
endmodule
