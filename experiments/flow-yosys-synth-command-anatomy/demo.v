// 最小演示设计：计数器 + 16x8 同步存储器
// 用于观察 synth 宏各段（hierarchy/proc/fsm/memory/techmap 等）的产物变化
module demo (
    input        clk,
    input        rst_n,
    input        we,
    input  [3:0] addr,
    input  [7:0] wdata,
    output reg [7:0] rdata,
    output reg [2:0] cnt
);
    reg [7:0] mem [0:15];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        rdata <= mem[addr];
        if (!rst_n)
            cnt <= 3'd0;
        else
            cnt <= cnt + 3'd1;
    end
endmodule
