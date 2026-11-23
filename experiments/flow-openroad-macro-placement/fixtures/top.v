module top_macro (
  input  wire clk,
  input  wire addr,
  input  wire din,
  output wire dout
);
  SRAM64 u_sram0 (
    .clk(clk), .addr(addr), .dout(dout)
  );
  SRAM40 u_sram1 (
    .clk(clk), .din(din)
  );
endmodule
