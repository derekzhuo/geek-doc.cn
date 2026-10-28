module casex_fixed(input wire [3:0] op, output reg [1:0] sel);
  always @* begin
    case (op)
      4'b1011, 4'b1111:                 sel = 2'd1;  // 原 1x11：显式枚举，且优先级最高
      4'b1010, 4'b1110:                 sel = 2'd0;  // 原 1x1x 的剩余取值
      4'b0000, 4'b0001, 4'b0100, 4'b0101: sel = 2'd2;  // 原 0x0x
      default:                          sel = 2'd3;
    endcase
  end
endmodule
