// 场景 B 用：与 defs_order.v 分开编译，用 `BUS_W
module demo_order(input wire [`BUS_W-1:0] din,
                  output wire [`BUS_W-1:0] dout);
  assign dout = din;
endmodule
