module case_bad(input [1:0] sel, output reg [3:0] y);
  always @(*) begin
    case (sel)
      2'd0: y = 4'd1;
      2'd1: y = 4'd2;
      // 无 default、分支不全
    endcase
  end
endmodule
