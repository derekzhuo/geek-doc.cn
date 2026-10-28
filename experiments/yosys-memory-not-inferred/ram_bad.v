// 反例：组合 always 块里异步写数组（阻塞赋值、无时钟沿）
module ram_bad (
    input  wire        we,
    input  wire [7:0]  waddr,
    input  wire [7:0]  raddr,
    input  wire [15:0] din,
    output wire [15:0] dout
);
    reg [15:0] mem [0:255];

    always @(*) begin
        if (we) mem[waddr] = din;   // 异步写：不合 memory 推断模板
    end

    assign dout = mem[raddr];       // 异步读
endmodule
