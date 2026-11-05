// small_counter.v — minimal clocked design for the first sky130A OpenLANE run.
// Few thousand gates target: counter + enable + synchronous reset, no I/O complexity.
`default_nettype none
module small_counter #(
    parameter WIDTH = 12
)(
    input  wire             clk,
    input  wire             rst_n,   // synchronous active-low (mapped to abc reset)
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
