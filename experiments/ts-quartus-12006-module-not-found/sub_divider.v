// Parameterized tick divider: pulses tick one cycle when the counter wraps.
module sub_divider #(
    parameter WIDTH = 24
) (
    input  wire clk,
    input  wire rst_n,
    output reg  tick
);
    reg [WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= {WIDTH{1'b0}};
            tick <= 1'b0;
        end else begin
            cnt  <= cnt + 1'b1;
            tick <= &cnt;
        end
    end
endmodule
