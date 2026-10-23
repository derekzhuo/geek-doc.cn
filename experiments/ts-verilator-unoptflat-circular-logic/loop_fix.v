// 拆环修复：把 z 打一拍寄存，组合环被时序单元切断
// verilator --lint-only -Wall loop_fix.v
// 预期：无任何告警，exit 0
module loop_fix (
    input  wire clk,
    input  wire sel,
    input  wire a,
    input  wire b,
    output reg  y
);
    reg z_q;
    wire x;
    assign x = sel ? a : z_q;
    always @(posedge clk) begin
        z_q <= sel ? b : x;
        y   <= x & z_q;
    end
endmodule
