// axi_lite_regs.v — minimal AXI4-Lite slave, 4 x 32-bit registers.
// Lab target: self-checking Icarus TB (read/write, decode error / SLVERR path).
// Implements AW/W/AR channels (VALID/READY handshake), B and R responses.
`default_nettype none
module axi_lite_regs #(
    parameter ADDR_MASK = 32'h0000_000f   // 4 registers
)(
    input  wire        aclk, aresetn,

    // write address
    input  wire [31:0] awaddr,  input  wire awvalid, output reg awready,
    // write data
    input  wire [31:0] wdata,   input  wire wvalid,  output reg wready,
    input  wire [ 3:0] wstrb,
    // write response
    output reg  [ 1:0] bresp,   output reg  bvalid,  input  wire bready,

    // read address
    input  wire [31:0] araddr,  input  wire arvalid, output reg arready,
    // read data
    output reg  [31:0] rdata,   output reg  [ 1:0] rresp,
    output reg         rvalid,  input  wire rready
);
    reg [31:0] regs [0:3];
    integer i;
    initial for (i=0;i<4;i=i+1) regs[i] = 32'h0;

    // simple valid/ready: accept on the cycle both are high (single-beat Lite)
    wire wr_fire = awvalid && awready && wvalid && wready;
    wire rd_fire = arvalid && arready;

    // accepted write address held until B handshake
    reg [31:0] awaddr_q;
    reg        decode_err_q;

    always @(posedge aclk) begin
        if (!aresetn) begin
            awready <= 0; wready <= 0; bvalid <= 0; bresp <= 2'b00;
            arready <= 0; rvalid <= 0; rdata <= 0; rresp <= 2'b00;
            awaddr_q <= 0; decode_err_q <= 0;
        end else begin
            // write channel
            awready <= awvalid && wvalid && !bvalid;
            wready  <= awvalid && wvalid && !bvalid;
            if (wr_fire) begin
                awaddr_q <= awaddr;
                if (awaddr[3:2] <= 2'd3 && (awaddr & ~ADDR_MASK) == 0) begin
                    // byte strobes honored
                    if (wstrb[0]) regs[awaddr[3:2]][ 7: 0] <= wdata[ 7: 0];
                    if (wstrb[1]) regs[awaddr[3:2]][15: 8] <= wdata[15: 8];
                    if (wstrb[2]) regs[awaddr[3:2]][23:16] <= wdata[23:16];
                    if (wstrb[3]) regs[awaddr[3:2]][31:24] <= wdata[31:24];
                    decode_err_q <= 0;
                end else begin
                    decode_err_q <= 1;   // out of range -> SLVERR
                end
                bvalid <= 1;
                bresp  <= ((awaddr[3:2] <= 2'd3) && ((awaddr & ~ADDR_MASK)==0)) ? 2'b00 : 2'b10;
            end
            if (bvalid && bready) begin bvalid <= 0; decode_err_q <= 0; end

            // read channel
            arready <= arvalid && !rvalid;
            if (rd_fire) begin
                rvalid <= 1;
                if (araddr[3:2] <= 2'd3 && (araddr & ~ADDR_MASK) == 0) begin
                    rdata <= regs[araddr[3:2]];
                    rresp <= 2'b00;
                end else begin
                    rdata <= 32'h0;
                    rresp <= 2'b10;  // SLVERR
                end
            end
            if (rvalid && rready) rvalid <= 0;
        end
    end
endmodule
`default_nettype wire
