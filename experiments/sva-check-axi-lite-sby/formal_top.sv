// formal_top.sv — wrapper: instantiate DUT + checker with plain wires (bind替代)
module formal_top (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [31:0] awaddr,
    input  wire        awvalid,
    output wire        awready,
    input  wire [31:0] wdata,
    input  wire        wvalid,
    output wire        wready,
    input  wire [ 3:0] wstrb,
    output wire [ 1:0] bresp,
    output wire        bvalid,
    input  wire        bready,
    input  wire [31:0] araddr,
    input  wire        arvalid,
    output wire        arready,
    output wire [31:0] rdata,
    output wire [ 1:0] rresp,
    output wire        rvalid,
    input  wire        rready
);
    axi_lite_regs_fixed dut (
        .aclk(aclk), .aresetn(aresetn),
        .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wvalid(wvalid), .wready(wready), .wstrb(wstrb),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rvalid(rvalid), .rready(rready)
    );

    axi_lite_checker chk (
        .aclk(aclk), .aresetn(aresetn),
        .rvalid(rvalid), .rready(rready), .rdata(rdata),
        .bvalid(bvalid), .bready(bready)
    );
endmodule
