// 修复版：真 bug 修掉（比较值收窄到 8 位可达范围），有意截断保留最小豁免
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

    // 高位地址与写数据高 8 位本设计不用，显式汇总到 unused_ok 声明"确认不用"
    wire unused_ok = &{1'b0, addr[31:4], wdata[15:8]};

    always @(posedge clk) begin
        if (we)
            regs[addr[3:0]] <= wdata[7:0];
        // 修复：8 位计数器与 8 位常量比较，位宽一致，逻辑可达
        if (cnt == 8'd200)
            cnt <= 8'd0;
        else
            cnt <= cnt + 8'd1;
    end
endmodule
