module lane #(
    parameter WIDTH = 5,
    parameter [WIDTH-1:0] RESET_VALUE = {WIDTH{1'b0}}
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    (* keep = 1 *) wire [WIDTH-1:0] next_q;
    assign next_q = en ? d : q;

    always @(posedge clk) begin
        if (rst)
            q <= RESET_VALUE;
        else
            q <= next_q;
    end
endmodule

module top (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire [4:0] d,
    output wire [4:0] q
);
    (* keep_hierarchy = 1 *)
    lane #(
        .WIDTH(5),
        .RESET_VALUE(5'b00101)
    ) u_lane (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q)
    );

    (* mark_debug = "true" *) wire [4:0] observed;
    assign observed = q;
endmodule
