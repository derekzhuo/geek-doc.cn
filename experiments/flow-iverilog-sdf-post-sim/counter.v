`timescale 1ps/1ps
// 最小教学设计：带使能与进位的 4 位计数器，异步低电平复位。
// 四个触发器拆成标量写法，使综合网表中的实例名不带位选括号。
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [3:0] q,
    output wire       carry
);
    reg q0, q1, q2, q3;
    wire [3:0] next = {q3, q2, q1, q0} + 4'd1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {q3, q2, q1, q0} <= 4'd0;
        else if (en) begin
            q0 <= next[0];
            q1 <= next[1];
            q2 <= next[2];
            q3 <= next[3];
        end
    end

    assign q     = {q3, q2, q1, q0};
    assign carry = en & ({q3, q2, q1, q0} == 4'd15);
endmodule
