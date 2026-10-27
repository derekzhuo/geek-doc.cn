// req_ack_bad.v — BUG: ack simply follows req (double-acks a held request,
// violating the one-cycle-pulse spec)
module req_ack_bad (
    input  wire clk,
    input  wire rst_n,
    input  wire req,
    output reg  ack
);
    always @(posedge clk) begin
        if (!rst_n) ack <= 1'b0;
        else        ack <= req;           // BUG: ack stays high as long as req is held
    end

`ifdef FORMAL
    // same master assumptions as the good design
    always @(posedge clk)
        if (rst_n && $past(rst_n)) begin
            if ($past(req) && !$past(ack)) assume (req);
            if ($past(ack))                assume (!req);
        end
    // A1: ack is high exactly one cycle after a pending request
    always @(posedge clk)
        if (rst_n && $past(rst_n))
            assert (ack == ($past(req) && !$past(ack)));
    // A2: no spurious ack while req is low
    always @(posedge clk)
        if (rst_n)
            assert (!ack || req);
`endif
endmodule
