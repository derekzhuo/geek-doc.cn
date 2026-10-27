// axi4_slave.v — minimal AXI4-Full slave, INCR burst, single outstanding transaction
`timescale 1ns/1ps
module axi4_slave (
    input  wire        aclk,
    input  wire        aresetn,

    // write address channel
    input  wire [31:0] awaddr,
    input  wire [ 7:0] awlen,
    input  wire [ 2:0] awsize,
    input  wire [ 1:0] awburst,
    input  wire        awvalid,
    output reg         awready,

    // write data channel
    input  wire [31:0] wdata,
    input  wire [ 3:0] wstrb,
    input  wire        wlast,
    input  wire        wvalid,
    output reg         wready,

    // write response channel
    output reg  [ 1:0] bresp,
    output reg         bvalid,
    input  wire        bready,

    // read address channel
    input  wire [31:0] araddr,
    input  wire [ 7:0] arlen,
    input  wire [ 2:0] arsize,
    input  wire [ 1:0] arburst,
    input  wire        arvalid,
    output reg         arready,

    // read data channel
    output reg  [31:0] rdata,
    output reg  [ 1:0] rresp,
    output reg         rlast,
    output reg         rvalid,
    input  wire        rready
);
    reg [31:0] mem [0:255];

    // ---- write ----
    reg [31:0] waddr_q;
    reg [ 7:0] wlen_q;
    always @(posedge aclk) begin
        if (!aresetn) begin
            awready <= 1'b0; wready <= 1'b0;
            bvalid <= 1'b0; bresp <= 2'b00;
            waddr_q <= 0; wlen_q <= 0;
        end else begin
            // accept write address when idle
            awready <= !wready && !bvalid;
            if (awvalid && awready) begin
                waddr_q <= awaddr;
                wlen_q  <= awlen;
                wready  <= 1'b1;   // ready to take data beats
            end
            if (wvalid && wready) begin
                mem[waddr_q[9:2]] <= wdata;
                waddr_q <= waddr_q + 4;
                if (wlast) begin
                    wready <= 1'b0;
                    bvalid <= 1'b1;  // OKAY
                end
            end
            if (bvalid && bready) bvalid <= 1'b0;
        end
    end

    // ---- read ----
    reg [31:0] raddr_q;
    reg [ 7:0] rlen_q;
    always @(posedge aclk) begin
        if (!aresetn) begin
            arready <= 1'b0; rvalid <= 1'b0; rresp <= 2'b00; rlast <= 1'b0;
            rdata <= 0; raddr_q <= 0; rlen_q <= 0;
        end else begin
            arready <= !rvalid;
            if (arvalid && arready) begin
                raddr_q <= araddr;
                rlen_q  <= arlen;
                rvalid  <= 1'b1;
                rdata   <= mem[araddr[9:2]];
                rlast   <= (arlen == 0);
            end else if (rvalid && rready) begin
                if (rlast) begin
                    rvalid <= 1'b0;
                    rlast  <= 1'b0;
                end else begin
                    raddr_q <= raddr_q + 4;
                    rdata   <= mem[(raddr_q[9:2]) + 1];
                    rlen_q  <= rlen_q - 1;
                    rlast   <= (rlen_q == 1);
                end
            end
        end
    end
endmodule
