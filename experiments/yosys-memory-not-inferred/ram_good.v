// 正例：标准同步 RAM 模板——写时序、读时序，各占一个过程块语义清晰
module ram_good (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  waddr,
    input  wire [7:0]  raddr,
    input  wire [15:0] din,
    output reg  [15:0] dout
);
    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
        dout <= mem[raddr];   // 同步读：地址与数据都拍一拍
    end
endmodule
