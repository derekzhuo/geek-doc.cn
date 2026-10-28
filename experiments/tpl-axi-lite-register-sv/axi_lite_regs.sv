// axi_lite_regs.sv
// AXI4-Lite 从机寄存器接口模板（iverilog -g2012 / Verilator -Wall 均可过）
// 寄存器映射（字地址 = 字节地址 >> 2）：
//   0x00 CTRL       RW  bit[1:0] = {err_irq_en, done_irq_en}，其余位用户自定义
//   0x04 STATUS     RO  bit[1:0] = {error_in, busy_in}（来自用户逻辑的实时电平）
//   0x08 IRQ_STATUS W1C bit[1:0] = {err_sticky, done_sticky}，写 1 清除
// 中断输出 irq = |(IRQ_STATUS & CTRL[1:0])
`timescale 1ns/1ps
`default_nettype none

module axi_lite_regs #(
    parameter ADDR_WIDTH = 6,               // 字节地址宽度，6 => 64B = 16 个 32 位寄存器
    parameter DATA_WIDTH = 32
) (
    input  wire                     aclk,
    input  wire                     aresetn,

    // AW 写地址通道
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    // W 写数据通道
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    // B 写响应通道
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,
    // AR 读地址通道
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,
    // R 读数据通道
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,

    // 用户逻辑接口
    input  wire                     busy_in,     // 实时状态电平
    input  wire                     error_in,
    input  wire                     evt_done,    // 单拍事件脉冲，置位 sticky
    input  wire                     evt_error,
    output reg  [DATA_WIDTH-1:0]    ctrl_reg,    // 控制寄存器输出
    output wire                     irq
);

    // 寄存器字地址（字节地址右移 2 位，地址低 2 位不参与译码）
    localparam REG_CTRL       = 4'h0;  // 0x00
    localparam REG_STATUS     = 4'h1;  // 0x04
    localparam REG_IRQ_STATUS = 4'h2;  // 0x08

    // AXI 响应码：00 = OKAY
    localparam RESP_OKAY = 2'b00;

    // 写通道握手保持寄存器
    reg [ADDR_WIDTH-3:0]       awaddr_q;   // 已锁存的写字地址（字地址）
    reg                        awpend_q;   // AW 已握手、等待 W
    reg [DATA_WIDTH-1:0]       wdata_q;
    reg [DATA_WIDTH/8-1:0]     wstrb_q;
    reg                        wpend_q;    // W 已握手、等待 AW

    // 读通道：地址在 AR 握手当拍直接译码，无需锁存

    // 中断状态 sticky 位
    reg [1:0]                  irq_sticky_q;

    wire wr_fire = awpend_q & wpend_q & ~s_axi_bvalid;
    wire [3:0] wr_addr = awaddr_q[3:0];

    assign irq = |(irq_sticky_q & ctrl_reg[1:0]);

    // 地址低两位为字节内偏移，本模板按字对齐访问，不参与译码
    wire unused_ok = &{1'b0, s_axi_awaddr[1:0], s_axi_araddr[1:0]};

    // ------------------------------------------------------------------
    // AW 与 W 通道：各自独立握手，双方到齐后合并成一次写事务
    // ------------------------------------------------------------------
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            awaddr_q      <= {ADDR_WIDTH-2{1'b0}};
            awpend_q      <= 1'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid) begin
                awaddr_q      <= s_axi_awaddr[ADDR_WIDTH-1:2];
                awpend_q      <= 1'b1;
                s_axi_awready <= 1'b0;
            end else if (wr_fire) begin
                awpend_q      <= 1'b0;
                s_axi_awready <= 1'b1;
            end else if (!awpend_q && !s_axi_awready) begin
                s_axi_awready <= 1'b1;   // 初始/完成后回到可接收态
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_wready <= 1'b0;
            wdata_q      <= {DATA_WIDTH{1'b0}};
            wstrb_q      <= {(DATA_WIDTH/8){1'b0}};
            wpend_q      <= 1'b0;
        end else begin
            if (s_axi_wready && s_axi_wvalid) begin
                wdata_q      <= s_axi_wdata;
                wstrb_q      <= s_axi_wstrb;
                wpend_q      <= 1'b1;
                s_axi_wready <= 1'b0;
            end else if (wr_fire) begin
                wpend_q      <= 1'b0;
                s_axi_wready <= 1'b1;
            end else if (!wpend_q && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // 寄存器写译码：AW/W 双方到齐当拍生效；W1C 位由软件写 1 清除
    // ------------------------------------------------------------------
    integer i;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ctrl_reg     <= {DATA_WIDTH{1'b0}};
            irq_sticky_q <= 2'b00;
        end else begin
            // 事件脉冲置位 sticky（与软件清除同拍时，置位优先）
            if (evt_done)  irq_sticky_q[0] <= 1'b1;
            if (evt_error) irq_sticky_q[1] <= 1'b1;

            if (wr_fire) begin
                case (wr_addr)
                    REG_CTRL: begin
                        for (i = 0; i < DATA_WIDTH/8; i = i + 1)
                            if (wstrb_q[i])
                                ctrl_reg[i*8 +: 8] <= wdata_q[i*8 +: 8];
                    end
                    REG_IRQ_STATUS: begin
                        // W1C：写 1 的位清零；与上方置位同拍时置位优先
                        if (wstrb_q[0]) begin
                            if (wdata_q[0] && !evt_done)  irq_sticky_q[0] <= 1'b0;
                            if (wdata_q[1] && !evt_error) irq_sticky_q[1] <= 1'b0;
                        end
                    end
                    default: ; // STATUS 只读、未定义地址，写操作静默丢弃
                endcase
            end
        end
    end

    // ------------------------------------------------------------------
    // B 写响应通道：写生效当拍拉高 bvalid，主机 bready 接收后撤下
    // ------------------------------------------------------------------
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;
        end else begin
            if (wr_fire) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= RESP_OKAY;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // AR 通道：空闲时 arready 拉高，握手当拍锁存地址并给出 rvalid
    // ------------------------------------------------------------------
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_arready <= 1'b1;
            end else if (!s_axi_arready && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // R 通道与读多路选择：地址锁存后组合译码，rvalid 保持到主机接收
    // ------------------------------------------------------------------
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= RESP_OKAY;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= RESP_OKAY;
                case (s_axi_araddr[ADDR_WIDTH-1:2])
                    REG_CTRL:       s_axi_rdata <= ctrl_reg;
                    REG_STATUS:     s_axi_rdata <= {{(DATA_WIDTH-2){1'b0}}, error_in, busy_in};
                    REG_IRQ_STATUS: s_axi_rdata <= {{(DATA_WIDTH-2){1'b0}}, irq_sticky_q};
                    default:        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
`default_nettype wire
