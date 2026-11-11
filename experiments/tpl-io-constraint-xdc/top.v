/* 教学用最小 RTL：一个时钟、一组同步输入、一组寄存器输出、
   一个组合直达输出、一个纯输出口（用于演示虚拟时钟）。 */
module top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] din,
    output wire [3:0] dout,
    output wire       combo,
    output reg        led
);
    reg [3:0] dreg;

    always @(posedge clk) begin
        if (!rst_n) begin
            dreg <= 4'b0000;
            led  <= 1'b0;
        end else begin
            dreg <= din;
            led  <= &din;
        end
    end

    assign dout  = dreg;
    assign combo = ~din[0];
endmodule
