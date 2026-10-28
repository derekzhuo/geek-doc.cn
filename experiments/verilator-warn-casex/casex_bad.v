module casex_bad(input wire [3:0] op, output reg [1:0] sel);
  always @* begin
    casex (op)
      4'b1x1x: sel = 2'd0;   // 想匹配 1?1?，但与下一项在 4'b1011/4'b1111 上重叠
      4'b1x11: sel = 2'd1;   // 优先级更低，永远抢不过上一项
      4'b0x0x: sel = 2'd2;
      default: sel = 2'd3;
    endcase
  end
endmodule
