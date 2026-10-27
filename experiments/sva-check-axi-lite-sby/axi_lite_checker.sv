// axi_lite_checker.sv — SVA checker bound onto the AXI-Lite slave (immediate-assertion style)
module axi_lite_checker (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        rvalid,
    input  wire        rready,
    input  wire [31:0] rdata,
    input  wire        bvalid,
    input  wire        bready
);
    // A1: once RVALID is up it must not be withdrawn before the handshake completes
    always @(posedge aclk)
        if (aresetn && $past(aresetn))
            assert (!($past(rvalid) && !$past(rready)) || rvalid);
    // A2: RDATA must stay stable while the read data channel is stalled
    always @(posedge aclk)
        if (aresetn && $past(aresetn))
            assert (!($past(rvalid) && !$past(rready)) || $stable(rdata));
    // A3: BVALID likewise must not retract before BREADY
    always @(posedge aclk)
        if (aresetn && $past(aresetn))
            assert (!($past(bvalid) && !$past(bready)) || bvalid);
endmodule
