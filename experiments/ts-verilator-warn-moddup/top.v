module top (
    input  wire clk,
    output wire pulse
);
  pulse_dup u_pulse (
      .clk   (clk),
      .pulse (pulse)
  );
endmodule
