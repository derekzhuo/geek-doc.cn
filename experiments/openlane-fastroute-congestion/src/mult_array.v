module mult_array(input wire clk, input wire rst_n,
  input  wire [15:0] a0, input wire [15:0] b0,
  input  wire [15:0] a1, input wire [15:0] b1,
  input  wire [15:0] a2, input wire [15:0] b2,
  input  wire [15:0] a3, input wire [15:0] b3,
  output reg [35:0] acc);
  wire [31:0] p0 = a0 * b0;
  wire [31:0] p1 = a1 * b1;
  wire [31:0] p2 = a2 * b2;
  wire [31:0] p3 = a3 * b3;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) acc <= 36'd0;
    else acc <= acc + p0 + p1 + p2 + p3;
  end
endmodule
