// fsm_walker: parameterized bounded linear-walk controller.
//
// States S0..S(NSTATES-1) form a strictly adjacent sequence:
//   - go   (and not back): move one state forward, clamp at the last state
//   - back:                move one state backward, clamp at S0
//   - neither:             stay
// Every legal transition is adjacent-or-stay, which is exactly the
// precondition under which Gray encoding is safe (one bit toggles at a time).
//
// The RTL is identical for all three encodings: only the parameter
// ENCODING ("BIN" / "GRAY" / "OH") changes the state-vector width and the
// code of each state. This keeps the comparison fair.
module fsm_walker
#(
    parameter integer NSTATES  = 8,
    parameter integer ENC      = 0     // 0=BIN, 1=GRAY, 2=ONE-HOT
)(
    input  wire clk,
    input  wire rst_n,      // synchronous reset, active low
    input  wire go,         // walk forward
    input  wire back,       // walk backward (wins over go)
    output wire at_first_o, // state == S0
    output wire at_last_o,  // state == S(NSTATES-1)
    output wire at_mid_o,   // state == S(NSTATES/2)
    output wire busy_o      // state != S0
);
    localparam integer W  = $clog2(NSTATES);
    localparam integer SW = (ENC == 2) ? NSTATES : W;

    function [SW-1:0] enc(input integer i);
        integer j;
        reg [W-1:0] g;
        begin
            if (ENC == 2) begin
                enc = ({{(SW-1){1'b0}}, 1'b1} << i);
            end else begin
                for (j = 0; j < W; j = j+1)
                    g[j] = i[j] ^ ((j == W-1) ? 1'b0 : i[j+1]);
                if (ENC == 1)
                    enc = g;
                else
                    enc = i[W-1:0];
            end
        end
    endfunction

    reg [SW-1:0] state;
    reg [W-1:0]  idx;
    reg [SW-1:0] next_code;
    integer k;

    // decode current state index from the encoded state vector
    always @(*) begin
        idx = {W{1'b0}};
        for (k = 0; k < NSTATES; k = k+1)
            if (state == enc(k))
                idx = k[W-1:0];
    end

    wire mvf = go & ~back;
    wire mvb = back;

    always @(*) begin
        next_code = state;
        if (mvb) begin
            if (idx == 0)
                next_code = enc(0);
            else
                next_code = enc(idx - 1);
        end else if (mvf) begin
            if (idx == NSTATES-1)
                next_code = enc(NSTATES-1);
            else
                next_code = enc(idx + 1);
        end
    end

    always @(posedge clk) begin
        if (!rst_n)
            state <= enc(0);
        else
            state <= next_code;
    end

    assign at_first_o = (state == enc(0));
    assign at_last_o  = (state == enc(NSTATES-1));
    assign at_mid_o   = (state == enc(NSTATES/2));
    assign busy_o     = (state != enc(0));
endmodule
