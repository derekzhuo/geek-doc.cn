// axi_lite_regs_bad.v — BUG copy of labs/axi-lite-slave: rvalid retracts after 1 cycle
// even when rready is low, and rdata is free to change (violates AXI stall rules)
module axi_lite_regs_bad #(
    parameter ADDR_MASK = 32'h0000_000f
)(
    input  wire        aclk, aresetn,
    input  wire [31:0] awaddr,  input  wire awvalid, output reg awready,
    input  wire [31:0] wdata,   input  wire wvalid,  output reg wready,
    input  wire [ 3:0] wstrb,
    output reg  [ 1:0] bresp,   output reg  bvalid,  input  wire bready,
    input  wire [31:0] araddr,  input  wire arvalid, output reg arready,
    output reg  [31:0] rdata,   output reg  [ 1:0] rresp,
    output reg         rvalid,  input  wire rready
);
    reg [31:0] regs [0:3];
    integer i;
    initial for (i=0;i<4;i=i+1) regs[i] = 32'h0;

    wire rd_fire = arvalid && arready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            awready <= 0; wready <= 0; bvalid <= 0; bresp <= 2'b00;
            arready <= 0; rvalid <= 0; rdata <= 0; rresp <= 2'b00;
        end else begin
            awready <= awvalid && wvalid && !bvalid;
            wready  <= awvalid && wvalid && !bvalid;
            if (awvalid && awready && wvalid && wready) begin
                bvalid <= 1; bresp <= 2'b00;
                regs[awaddr[3:2]] <= wdata;
            end
            if (bvalid && bready) bvalid <= 0;

            arready <= arvalid && !rvalid;
            if (rd_fire) begin
                rvalid <= 1;
                rdata  <= regs[araddr[3:2]];
                rresp  <= 2'b00;
            end else begin
                // BUG: rvalid dropped next cycle even without rready,
                // and rdata allowed to change while stalled
                rvalid <= 0;
                if (!rready) rdata <= rdata + 1;
            end
        end
    end
endmodule
