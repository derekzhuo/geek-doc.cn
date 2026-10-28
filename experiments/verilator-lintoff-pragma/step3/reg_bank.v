// 正确姿势：只豁免确有理由的那一处，配对 lint_on 收口
module reg_bank (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [15:0] wdata,
    input  wire        we,
    output wire [7:0]  rdata,
    output wire [7:0]  led_data
);
    reg [7:0] regs [0:15];
    reg [7:0] cnt;

    assign rdata = regs[addr[3:0]];

    /* verilator lint_off WIDTHTRUNC */
    // 协议规定 LED 只显示写数据低 8 位，高 8 位由状态寄存器上报，截断是有意行为
    assign led_data = wdata;
    /* verilator lint_on WIDTHTRUNC */

    always @(posedge clk) begin
        if (we)
            regs[addr[3:0]] <= wdata[7:0];
        // 真 bug：cnt 只有 8 位，永远数不到 1000，这个比较恒为假
        if (cnt == 1000)
            cnt <= 8'd0;
        else
            cnt <= cnt + 8'd1;
    end
endmodule
