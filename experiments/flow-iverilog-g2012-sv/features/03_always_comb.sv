// 03 always_comb: 组合逻辑块
module t;
  logic [1:0] sel;
  logic [3:0] y;
  always_comb begin
    case (sel)
      2'd0: y = 4'b0001;
      2'd1: y = 4'b0010;
      2'd2: y = 4'b0100;
      default: y = 4'b1000;
    endcase
  end
  initial begin
    sel = 2'd2;
    #1 $display("PASS always_comb: y=%b (expect 0100)", y);
        $finish;
  end
endmodule
