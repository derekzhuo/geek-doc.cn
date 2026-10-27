// req_ack_good.v — ack pulses exactly one cycle after a pending req
module req_ack_good (
    input  wire clk,
    input  wire rst_n,
    input  wire req,
    output reg  ack
);
    always @(posedge clk) begin
        if (!rst_n) ack <= 1'b0;
        else        ack <= req && !ack;   // one-cycle pulse per request
    end

`ifdef FORMAL
    // master assumptions: hold req until ack; drop req right after ack
    always @(posedge clk)
        if (rst_n && $past(rst_n)) begin
            if ($past(req) && !$past(ack)) assume (req);
            if ($past(ack))                assume (!req);
        end
    // A1: ack is high exactly one cycle after a pending request (no earlier, no later)
    always @(posedge clk)
        if (rst_n && $past(rst_n))
            assert (ack == ($past(req) && !$past(ack)));
    // A2: no spurious ack while req is low
    always @(posedge clk)
        if (rst_n)
            assert (!ack || req);
`endif
endmodule
