// BAD: force/release are simulation control statements not supported
// by Vivado synthesis. Expect [Synth 8-3126] ... is not supported.
module force_bad (
    input  wire clk,
    input  wire rstn,
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q <= 1'b0;
        else
            q <= d;
    end

    // Testbench-style override leaking into synthesizable RTL.
    always @(posedge clk) begin
        force q = 1'b1;
        release q;
    end
endmodule
