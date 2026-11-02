// counter.v —— 两层层级的小计数器，用于展示 $dumpvars 的深度差异
// tb -> dut(cnt_top) -> u_inc(inc_add)
`timescale 1ns/1ps

module inc_add (
    input  wire [7:0] a,
    output wire [7:0] y
);
    assign y = a + 8'd1;
endmodule

module cnt_top (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [7:0] cnt,
    output wire       co
);
    wire [7:0] nxt;

    inc_add u_inc (.a(cnt), .y(nxt));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 8'd0;
        else
            cnt <= nxt;
    end

    assign co = &cnt;
endmodule
