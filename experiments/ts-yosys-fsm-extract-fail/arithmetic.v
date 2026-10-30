module arithmetic (
  input  wire clk,
  input  wire rst,
  input  wire start,
  input  wire finish,
  output wire ready,
  output wire done
);
  reg [1:0] state;

  always @(posedge clk) begin
    if (rst)
      state <= 2'd0;
    else if (state == 2'd2)
      state <= 2'd0;
    else if ((state == 2'd0 && start) ||
             (state == 2'd1 && finish))
      state <= state + 1'b1;
  end

  assign ready = (state == 2'd0);
  assign done  = (state == 2'd2);
endmodule
