// FIXED: one flop per clock domain, then combine the outputs with a mux.
module ambclk_fixed (
    input  wire clk1,
    input  wire clk2,
    input  wire sel,
    input  wire d1,
    input  wire d2,
    output wire q
);
    reg q1;
    reg q2;

    always @(posedge clk1) begin
        q1 <= d1;
    end

    always @(posedge clk2) begin
        q2 <= d2;
    end

    assign q = sel ? q1 : q2;
endmodule
