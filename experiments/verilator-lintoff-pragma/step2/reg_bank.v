// 错误示范：为消告警在文件顶部整片豁免，真 bug 一起被埋掉
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off UNUSEDSIGNAL */
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

    // 有意为之：协议规定 LED 只显示写数据的低 8 位
    assign led_data = wdata;

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
