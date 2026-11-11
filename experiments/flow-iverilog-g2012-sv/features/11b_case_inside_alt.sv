// 11b case inside 另一种语法位置
module t;
  logic [3:0] x;
  string r;
  always_comb begin
    case inside (x)
      4'd0, [4'd1:4'd3]: r = "low";
      [4'd4:4'd9]:       r = "mid";
      default:           r = "high";
    endcase
  end
  initial begin
    x = 4'd2; #1 $display("PASS case-inside-alt: x=%0d -> %s (expect low)", x, r);
    x = 4'd7; #1 $display("PASS case-inside-alt: x=%0d -> %s (expect mid)", x, r);
    $finish;
  end
endmodule
