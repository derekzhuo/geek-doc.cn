module blinky_fixed (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);

    reg [23:0] cnt;

    // 可综合改写：去掉 initial 里的 #10，初始化语义由异步复位表达，
    // LED 翻转逻辑全部留在时钟沿上
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led <= 1'b0;
        end else if (cnt == 24'd12000000) begin
            cnt <= 24'd0;
            led <= ~led;
        end else begin
            cnt <= cnt + 24'd1;
        end
    end

endmodule
