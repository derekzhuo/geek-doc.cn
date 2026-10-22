module case_ok(input [1:0] sel, output reg [3:0] y);
  always @(*) begin
    case (sel)
      2'd0: y = 4'd1;
      2'd1: y = 4'd2;
      default: y = 4'd0;
    endcase
  end
endmodule
