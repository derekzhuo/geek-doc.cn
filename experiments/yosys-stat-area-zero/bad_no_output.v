// bad_no_output.v: 逻辑写了但没有输出端口，synth 后全部被优化掉
module top(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] a,
    input  wire [7:0] b
);
    reg [7:0] acc;
    always @(posedge clk) begin
        if (!rst_n)
            acc <= 8'd0;
        else
            acc <= acc + a + b;
    end
    // 忘了把 acc 接到任何输出端口
endmodule
