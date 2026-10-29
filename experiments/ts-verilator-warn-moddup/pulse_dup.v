module pulse_dup (
    input  wire clk,
    output reg  pulse
);
  always @(posedge clk) pulse <= 1'b1;
endmodule
