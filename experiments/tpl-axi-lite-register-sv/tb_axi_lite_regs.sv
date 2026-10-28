// tb_axi_lite_regs.sv —— axi_lite_regs 最小自检 testbench（iverilog -g2012）
`timescale 1ns/1ps
`default_nettype none

module tb_axi_lite_regs;

    localparam ADDR_WIDTH = 6;
    localparam DATA_WIDTH = 32;

    reg                     aclk = 1'b0;
    reg                     aresetn = 1'b0;
    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr = {ADDR_WIDTH{1'b0}};
    reg                     s_axi_awvalid = 1'b0;
    wire                    s_axi_awready;
    reg  [DATA_WIDTH-1:0]   s_axi_wdata = {DATA_WIDTH{1'b0}};
    reg  [DATA_WIDTH/8-1:0] s_axi_wstrb = {(DATA_WIDTH/8){1'b0}};
    reg                     s_axi_wvalid = 1'b0;
    wire                    s_axi_wready;
    wire [1:0]              s_axi_bresp;
    wire                    s_axi_bvalid;
    reg                     s_axi_bready = 1'b0;
    reg  [ADDR_WIDTH-1:0]   s_axi_araddr = {ADDR_WIDTH{1'b0}};
    reg                     s_axi_arvalid = 1'b0;
    wire                    s_axi_arready;
    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;
    wire                    s_axi_rvalid;
    reg                     s_axi_rready = 1'b0;
    reg                     busy_in = 1'b0;
    reg                     error_in = 1'b0;
    reg                     evt_done = 1'b0;
    reg                     evt_error = 1'b0;
    wire [DATA_WIDTH-1:0]   ctrl_reg;
    wire                    irq;

    integer errors = 0;

    axi_lite_regs #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),
        .busy_in(busy_in), .error_in(error_in),
        .evt_done(evt_done), .evt_error(evt_error),
        .ctrl_reg(ctrl_reg), .irq(irq)
    );

    always #5 aclk = ~aclk;

    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data,
                   input [DATA_WIDTH/8-1:0] strb);
    begin
        @(posedge aclk);
        s_axi_awaddr <= addr; s_axi_awvalid <= 1'b1;
        s_axi_wdata  <= data; s_axi_wstrb <= strb; s_axi_wvalid <= 1'b1;
        s_axi_bready <= 1'b1;
        wait (s_axi_awready && s_axi_awvalid) @(posedge aclk);
        s_axi_awvalid <= 1'b0;
        wait (s_axi_wready && s_axi_wvalid) @(posedge aclk);
        s_axi_wvalid <= 1'b0;
        wait (s_axi_bvalid) @(posedge aclk);
        s_axi_bready <= 1'b0;
    end
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
    begin
        @(posedge aclk);
        s_axi_araddr <= addr; s_axi_arvalid <= 1'b1; s_axi_rready <= 1'b1;
        wait (s_axi_arready && s_axi_arvalid) @(posedge aclk);
        s_axi_arvalid <= 1'b0;
        wait (s_axi_rvalid) @(posedge aclk);
        data = s_axi_rdata;
        s_axi_rready <= 1'b0;
    end
    endtask

    task check(input [DATA_WIDTH-1:0] got, input [DATA_WIDTH-1:0] exp, input [127:0] name);
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("FAIL: %0s got=%h exp=%h", name, got, exp);
        end else begin
            $display("OK:   %0s = %h", name, got);
        end
    end
    endtask

    reg [DATA_WIDTH-1:0] rdata;

    initial begin
        repeat (4) @(posedge aclk);
        aresetn <= 1'b1;
        repeat (2) @(posedge aclk);

        // 1) 写 CTRL=0x3（使能两路中断）后读回
        axi_write(6'h00, 32'h0000_0003, 4'hF);
        axi_read (6'h00, rdata);
        check(rdata, 32'h0000_0003, "CTRL readback");

        // 2) 字节选通：先写全 1，再只写高两个字节
        axi_write(6'h00, 32'hFFFF_FFFF, 4'hF);
        axi_write(6'h00, 32'h0003_0000, 4'hC);
        axi_read (6'h00, rdata);
        check(rdata, 32'h0003_FFFF, "CTRL wstrb");

        // 3) STATUS 反映实时输入电平
        busy_in  = 1'b1;
        error_in = 1'b0;
        axi_read(6'h04, rdata);
        check(rdata, 32'h0000_0001, "STATUS busy");

        // 4) evt_done 置位 sticky，irq 因 CTRL[0]=1 拉高
        @(posedge aclk); evt_done <= 1'b1;
        @(posedge aclk); evt_done <= 1'b0;
        axi_read(6'h08, rdata);
        check(rdata & 32'h3, 32'h1, "IRQ_STATUS done");
        check({31'b0, irq}, 32'h1, "irq asserted");

        // 5) W1C 写 1 清除 done 位，irq 回落
        axi_write(6'h08, 32'h0000_0001, 4'hF);
        axi_read (6'h08, rdata);
        check(rdata, 32'h0000_0000, "IRQ_STATUS cleared");
        check({31'b0, irq}, 32'h0, "irq deasserted");

        // 6) 未定义地址读回 0
        axi_read(6'h3C, rdata);
        check(rdata, 32'h0000_0000, "undefined addr");

        if (errors == 0) $display("TEST PASS");
        else             $display("TEST FAIL: %0d errors", errors);
        $finish;
    end

endmodule
`default_nettype wire
