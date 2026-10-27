// axi_lite_regs_fixed.v — labs/axi-lite-slave RTL with a REAL bug fixed:
// original `arready <= arvalid && !rvalid` double-accepted AR while a previous
// read was stalled (rvalid && !rready), overwriting rdata mid-stall (SVA A2 catch).
// Fix: only accept AR when no read is pending and no acceptance is in flight.
module axi_lite_regs_fixed #(
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

    wire wr_fire = awvalid && awready && wvalid && wready;
    wire rd_fire = arvalid && arready;

    reg [31:0] awaddr_q;
    reg        decode_err_q;

    always @(posedge aclk) begin
        if (!aresetn) begin
            awready <= 0; wready <= 0; bvalid <= 0; bresp <= 2'b00;
            arready <= 0; rvalid <= 0; rdata <= 0; rresp <= 2'b00;
            awaddr_q <= 0; decode_err_q <= 0;
        end else begin
            // write channel (unchanged from lab version)
            awready <= awvalid && wvalid && !bvalid;
            wready  <= awvalid && wvalid && !bvalid;
            if (wr_fire) begin
                awaddr_q <= awaddr;
                if (awaddr[3:2] <= 2'd3 && (awaddr & ~ADDR_MASK) == 0) begin
                    if (wstrb[0]) regs[awaddr[3:2]][ 7: 0] <= wdata[ 7: 0];
                    if (wstrb[1]) regs[awaddr[3:2]][15: 8] <= wdata[15: 8];
                    if (wstrb[2]) regs[awaddr[3:2]][23:16] <= wdata[23:16];
                    if (wstrb[3]) regs[awaddr[3:2]][31:24] <= wdata[31:24];
                    decode_err_q <= 0;
                end else begin
                    decode_err_q <= 1;
                end
                bvalid <= 1;
                bresp  <= ((awaddr[3:2] <= 2'd3) && ((awaddr & ~ADDR_MASK)==0)) ? 2'b00 : 2'b10;
            end
            if (bvalid && bready) begin bvalid <= 0; decode_err_q <= 0; end

            // read channel — FIXED: no double-accept while rvalid is stalled
            arready <= arvalid && !rvalid && !arready;
            if (rd_fire) begin
                rvalid <= 1;
                if (araddr[3:2] <= 2'd3 && (araddr & ~ADDR_MASK) == 0) begin
                    rdata <= regs[araddr[3:2]];
                    rresp <= 2'b00;
                end else begin
                    rdata <= 32'h0;
                    rresp <= 2'b10;
                end
            end
            if (rvalid && rready) rvalid <= 0;
        end
    end
endmodule
