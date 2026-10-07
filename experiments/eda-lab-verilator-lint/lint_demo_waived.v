// lint_demo_waived.v —— 同 lint_demo.v，但用 /* verilator lint_off XXX */ 注释豁免两类告警
// 演示 waiver 方式一：源码内 lint_off/lint_on 注释（局部、贴着代码走）

module lint_demo_waived (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  din,
    input  wire [1:0]  sel,
    input  wire        unused_port,
    output reg  [15:0] dout,
    output wire        loop_out
);

    reg  [7:0]  a8;
    reg  [3:0]  nibble;

    always @(posedge clk) begin
        if (!rst_n) begin
            a8     <= 8'd0;
            nibble <= 4'd0;
        end else begin
            a8     <= din + 8'd1;
            /* verilator lint_off WIDTH */
            nibble <= 32'd7;              // 已评审：截断是有意为之，waiver 掉
            /* verilator lint_on WIDTH */
        end
    end

    always @(*) begin
        dout = {8'd0, a8 + din};          // 顺手修掉：显式补高 8 位，WIDTH 告警消失
    end

    /* verilator lint_off UNOPTFLAT */
    wire loop_x;
    wire loop_y;
    assign loop_x = loop_y & din[0];
    assign loop_y = loop_x | din[1];
    /* verilator lint_on UNOPTFLAT */
    assign loop_out = loop_x;

    reg q_latch;
    always @(*) begin
        if (din[2]) begin
            q_latch = din[3];
        end
    end

    wire [3:0] never_used;
    wire       never_driven;

    reg [7:0] mux_out;
    always @(*) begin
        case (sel)
            2'b00:   mux_out = din;
            2'b01:   mux_out = ~din;
            2'b10:   mux_out = 8'hAA;
        endcase
    end

endmodule
