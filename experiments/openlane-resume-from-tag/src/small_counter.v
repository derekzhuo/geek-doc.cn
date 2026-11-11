// small_counter.v -- minimal clocked design for OpenLane sky130A error-log labs.
`default_nettype none
module small_counter #(
    parameter WIDTH = 12
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    output reg [WIDTH-1:0]  count,
    output wire             wrap
);
    always @(posedge clk) begin
        if (!rst_n) count <= {WIDTH{1'b0}};
        else if (en) count <= count + 1'b1;
    end
    assign wrap = (count == {WIDTH{1'b1}});
endmodule
`default_nettype wire
